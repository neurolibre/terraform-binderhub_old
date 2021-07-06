#!/bin/bash
#waiting for k8s initialization
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 10; done
while [ ! -f /shared/k8s-initialized ]; do sleep 1; done

cd /home/${admin_user}

#Persistent volume
kubectl create -f pv.yaml

# TLS certificate management
# cert-manager
kubectl create namespace cert-manager
sudo helm repo add jetstack https://charts.jetstack.io
sudo helm repo update
sudo helm install --name cert-manager --namespace cert-manager --version v1.0.3 jetstack/cert-manager --set installCRDs=true \
--set nodeSelector."node-role\.kubernetes\.io/master=" \
--set cainjector.nodeSelector."node-role\.kubernetes\.io/master=" \
--set webhook.nodeSelector."node-role\.kubernetes\.io/master="
#wait until cert-manager is ready
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=300s
# apply the issuer(s)
kubectl create namespace binderhub
kubectl apply -f staging-binderhub-issuer.yaml
kubectl apply -f production-binderhub-issuer.yaml

# Binderhub proxy
sudo helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx/
sudo helm install --name binderhub-proxy --namespace=binderhub ingress-nginx/ingress-nginx -f nginx-ingress.yaml
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
# Grafana and prometheus
# https://github.com/pangeo-data/pangeo-binder#binder-monitoring
sudo helm repo add grafana https://grafana.github.io/helm-charts
sudo helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
sudo helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
sudo helm repo update
sudo helm install grafana-prod grafana/grafana
sudo helm install prometheus-prod prometheus-community/prometheus
