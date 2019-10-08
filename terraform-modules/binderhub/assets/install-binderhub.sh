#!/bin/bash
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 10; done

cd /home/${admin_user}
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
kubectl --namespace kube-system create serviceaccount tiller
helm init --service-account tiller --wait
kubectl patch deployment tiller-deploy --namespace=kube-system --type=json --patch='[{"op": "add", "path": "/spec/template/spec/containers/0/command", "value": ["/tiller", "--listen=localhost:44134"]}]'
kubectl create -f pv.yaml
sudo helm install --name nginx-ingress --namespace=support stable/nginx-ingress -f nginx-ingress.yaml
sudo helm install --name kube-lego --namespace=support stable/kube-lego -f kube-lego.yaml
sudo helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
sudo helm repo update
sudo helm install jupyterhub/binderhub --version=${binder_version} \
  --name=binderhub --namespace=binderhub -f config.yaml -f secrets.yaml
