#!/bin/bash
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 10; done

cd /home/${admin_user}

#Persistent volume
kubectl create -f pv.yaml

# Certificate manager
sudo helm install --name nginx-ingress --namespace=support stable/nginx-ingress -f nginx-ingress.yaml
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/v0.13.1/deploy/manifests/00-crds.yaml
kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  --name cert-manager \
  --namespace cert-manager \
  --version v0.13.1 \
  jetstack/cert-manager
kubectl apply -f staging-binderhub-issuer.yaml
kubectl get service nginx-ingress

# Binderhub
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
helm repo update
helm install jupyterhub/binderhub --version=${binder_version} \
  --name=binderhub --namespace=binderhub -f config.yaml -f secrets.yaml
sudo apt-get install git-crypt
