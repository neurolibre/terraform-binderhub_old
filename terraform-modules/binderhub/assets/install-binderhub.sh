#!/bin/bash
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 10; done

cd /home/${admin_user}

#Persistent volume
kubectl create -f pv.yaml

# Certificate manager
kubectl create namespace binderhub
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v0.13.1/cert-manager.yaml
kubectl apply -f production-binderhub-issuer.yaml
sudo helm install --name binderhub-proxy --namespace=binderhub stable/nginx-ingress -f nginx-ingress.yaml
kubectl get services --namespace binderhub binderhub-proxy-nginx-ingress-controller

# Binderhub
sudo helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
sudo helm repo update
sudo helm install jupyterhub/binderhub --version=${binder_version} \
  --name=binderhub --namespace=binderhub -f config.yaml -f secrets.yaml
sudo apt-get install git-crypt
