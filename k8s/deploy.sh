#!/bin/bash

# Kubernetes Deployment Scripti

set -e

DOMAIN="kelesabdullah.com"

echo "🚀 Kubernetes Deployment Başlatılıyor..."
echo ""

# Minikube kontrolü
if ! minikube status > /dev/null 2>&1; then
    echo "📦 Minikube başlatılıyor..."
    minikube start
fi

# Ingress controller kontrolü
echo "🔍 Ingress controller kontrol ediliyor..."
if ! kubectl get namespace ingress-nginx > /dev/null 2>&1; then
    echo "📦 Ingress controller kuruluyor..."
    minikube addons enable ingress
    echo "⏳ Ingress controller'ın hazır olması bekleniyor..."
    kubectl wait --namespace ingress-nginx \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=90s
fi

# Ingress controller service'i NodePort'a ayarla
echo "🔧 Ingress controller service'i NodePort'a ayarlanıyor..."
kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec":{"type":"NodePort"}}' 2>/dev/null || echo "   Zaten NodePort"

# Kubernetes kaynaklarını deploy et
echo "📋 Kubernetes kaynakları deploy ediliyor..."
kubectl apply -f depl1.yaml
kubectl apply -f svc1.yaml
kubectl apply -f ingress1.yaml

# Durum kontrolü
echo ""
echo "✅ Deployment tamamlandı!"
echo ""
echo "📊 Durum:"
kubectl get pods -l app=my-website
echo ""
kubectl get svc -l app=my-website
echo ""
kubectl get ingress
echo ""
echo "💡 Minikube IP: $(minikube ip)"
echo "💡 Sonraki adım: ./setup-nginx-proxy.sh"
