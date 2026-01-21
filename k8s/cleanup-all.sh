#!/bin/bash

# Tüm Ortamı Temizleme Scripti

set -e

echo "🧹 Tüm Ortamı Temizleme"
echo "========================"
echo ""

echo "⚠️  Bu script TÜM Kubernetes ve Nginx kaynaklarını silecektir!"
read -p "Devam etmek istiyor musunuz? (y/N): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "İşlem iptal edildi."
    exit 0
fi

echo ""
echo "1️⃣  Kubernetes kaynakları temizleniyor..."
kubectl delete ingress my-website-ingress 2>/dev/null || echo "   Ingress zaten yok"
kubectl delete service my-website-service 2>/dev/null || echo "   Service zaten yok"
kubectl delete deployment my-website 2>/dev/null || echo "   Deployment zaten yok"
echo "   ✅ Kubernetes kaynakları temizlendi"
echo ""

echo "2️⃣  Certificate kaynakları temizleniyor..."
kubectl delete certificate letsencrypt-tls 2>/dev/null || echo "   Certificate zaten yok"
kubectl delete certificaterequest --all 2>/dev/null || echo "   CertificateRequest yok"
kubectl delete order --all-namespaces --all 2>/dev/null || echo "   Order yok"
kubectl delete challenge --all-namespaces --all 2>/dev/null || echo "   Challenge yok"
kubectl delete secret letsencrypt-tls 2>/dev/null || echo "   Secret zaten yok"
kubectl delete secret wildcard-tls 2>/dev/null || echo "   Secret zaten yok"
echo "   ✅ Certificate kaynakları temizlendi"
echo ""

echo "3️⃣  ClusterIssuer temizleniyor..."
kubectl delete clusterissuer letsencrypt-prod 2>/dev/null || echo "   ClusterIssuer zaten yok"
echo "   ✅ ClusterIssuer temizlendi"
echo ""

echo "4️⃣  Cert-manager temizleniyor..."
kubectl delete namespace cert-manager 2>/dev/null || echo "   Cert-manager namespace zaten yok"
echo "   ✅ Cert-manager temizlendi"
echo ""

echo "5️⃣  Nginx config temizleniyor..."
sudo rm -f /etc/nginx/sites-enabled/kelesabdullah.com 2>/dev/null || echo "   Config zaten yok"
sudo rm -f /etc/nginx/sites-available/kelesabdullah.com 2>/dev/null || echo "   Config zaten yok"
echo "   ✅ Nginx config temizlendi"
echo ""

echo "6️⃣  Nginx SSL sertifikaları temizleniyor..."
sudo rm -rf /etc/nginx/ssl/kelesabdullah.com.* 2>/dev/null || echo "   SSL dosyaları zaten yok"
echo "   ✅ SSL dosyaları temizlendi"
echo ""

echo "7️⃣  Nginx reload ediliyor..."
sudo systemctl reload nginx 2>/dev/null || echo "   Nginx reload edilemedi (normal olabilir)"
echo ""

echo "✅ Temizlik tamamlandı!"
echo ""
echo "💡 Minikube'u da temizlemek isterseniz:"
echo "   minikube stop"
echo "   minikube delete"
