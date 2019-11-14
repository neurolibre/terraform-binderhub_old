#!/bin/bash
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 10; done

cd /home/${admin_user}
kubectl create -f pv.yaml
kubectl apply -f binderhub-issuer.yaml
sudo helm install stable/nginx-ingress --name quickstart
kubectl get service quickstart
sudo helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
sudo helm repo update
sudo helm install jupyterhub/binderhub --version=${binder_version} \
  --name=binderhub --namespace=binderhub -f config.yaml -f secrets.yaml
sudo apt-get install git-crypt
