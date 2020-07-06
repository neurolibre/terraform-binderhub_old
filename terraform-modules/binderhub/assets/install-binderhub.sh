#!/bin/bash
#waiting for k8s initialization
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 10; done
while [ ! -f /shared/k8s-initialized ]; do sleep 1; done

cd /home/${admin_user}

#Persistent volume
kubectl create -f pv.yaml

# TLS certificate management
# cert-manager
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/v0.13.1/deploy/manifests/00-crds.yaml
kubectl create namespace cert-manager
#kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
sudo helm repo add jetstack https://charts.jetstack.io
sudo helm repo update
# running on mster node to avoid issues with webhook not in the k8s network
sudo helm install \
  --name cert-manager \
  --namespace cert-manager \
  --version v0.13.1 \
  jetstack/cert-manager \
  --set nodeSelector."node-role\.kubernetes\.io/master=" \
  --set cainjector.nodeSelector."node-role\.kubernetes\.io/master=" \
  --set webhook.nodeSelector."node-role\.kubernetes\.io/master="

#kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=admin-user
#helm install --name cert-manager --namespace cert-manager --version v0.15.1 jetstack/cert-manager --set installCRDs=true --set nodeSelector."node-role\.kubernetes\.io/master=" --set cainjector.nodeSelector."node-role\.kubernetes\.io/master=" --set webhook.nodeSelector."node-role\.kubernetes\.io/master="

#wait until cert-manager is ready
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=300s
kubectl create namespace binderhub
kubectl apply -f staging-binderhub-issuer.yaml
kubectl apply -f production-binderhub-issuer.yaml

# Binderhub proxy
sudo helm install --name binderhub-proxy --namespace=binderhub stable/nginx-ingress -f nginx-ingress.yaml
# wait until nginx is ready (https://kubernetes.github.io/ingress-nginx/deploy/)
kubectl wait --namespace binderhub \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
kubectl get services --namespace binderhub binderhub-proxy-nginx-ingress-controller

# Binderhub
sudo helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
sudo helm repo update
sudo helm install jupyterhub/binderhub --version=${binder_version} \
  --name=binderhub --namespace=binderhub -f config.yaml -f secrets.yaml
sudo apt-get install git-crypt
