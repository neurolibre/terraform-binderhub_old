#!/bin/bash
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 10; done

cd /home/${admin_user}

# Install the CustomResourceDefinition resources separately
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml

# Create the namespace for cert-manager
kubectl create namespace cert-manager

# Label the cert-manager namespace to disable resource validation
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true

# Add the Jetstack Helm repository
sudo helm repo add jetstack https://charts.jetstack.io

# Update your local Helm chart repository cache
sudo helm repo update

# Install the cert-manager Helm chart
sudo helm install \
  --name cert-manager \
  --namespace cert-manager \
  --version v0.8.1 \
  jetstack/cert-manager

kubectl create -f pv.yaml
kubectl apply -f binderhub-issuer.yaml
sudo helm install stable/nginx-ingress --name quickstart
kubectl get service quickstart
sudo helm repo add jupyterhub https://jupyterhub.github.io/helm-chart
sudo helm repo update
sudo helm install jupyterhub/binderhub --version=${binder_version} \
  --name=binderhub --namespace=binderhub -f config.yaml -f secrets.yaml
sudo apt-get install git-crypt
