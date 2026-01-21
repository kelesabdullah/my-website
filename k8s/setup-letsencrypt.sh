#!/bin/bash

# Let's Encrypt SSL Sertifikası Kurulum Scripti

set -e

DOMAIN="kelesabdullah.com"
EMAIL="kelesabdullah@protonmail.com"

echo "🔐 Let's Encrypt SSL Sertifikası Kurulumu"
echo "=========================================="
echo ""

echo "1️⃣  Cert-Manager kurulumu kontrol ediliyor..."
if ! kubectl get namespace cert-manager > /dev/null 2>&1; then
    echo "📦 Cert-manager kuruluyor..."
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
    
    echo "⏳ Cert-manager'ın hazır olması bekleniyor (1-2 dakika)..."
    sleep 30
    kubectl wait --namespace cert-manager \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/instance=cert-manager \
      --timeout=300s || echo "   ⚠️  Timeout - devam ediliyor..."
else
    echo "   ✅ Cert-manager zaten kurulu"
fi
echo ""

echo "2️⃣  ClusterIssuer oluşturuluyor..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${EMAIL}
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

if [ $? -eq 0 ]; then
    echo "   ✅ ClusterIssuer oluşturuldu"
else
    echo "   ❌ ClusterIssuer oluşturulamadı!"
    exit 1
fi
echo ""

echo "3️⃣  ClusterIssuer'ın hazır olması bekleniyor..."
echo "   ⏳ ClusterIssuer'ın hazır olması bekleniyor (30 saniye)..."
for i in {1..15}; do
    CI_STATUS=$(kubectl get clusterissuer letsencrypt-prod -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")
    if [ "$CI_STATUS" = "True" ]; then
        echo "   ✅ ClusterIssuer hazır"
        break
    else
        if [ $((i % 5)) -eq 0 ]; then
            echo "   ⏳ Bekleniyor... ($i/15)"
        fi
        sleep 2
    fi
done

if [ "$CI_STATUS" != "True" ]; then
    echo "   ⚠️  ClusterIssuer henüz hazır değil, devam ediliyor..."
    echo "   ClusterIssuer durumu:"
    kubectl get clusterissuer letsencrypt-prod -o yaml | grep -A 10 "status:" | head -15
fi
echo ""

echo "4️⃣  Certificate oluşturuluyor..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: letsencrypt-tls
spec:
  secretName: letsencrypt-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - ${DOMAIN}
EOF

if [ $? -eq 0 ]; then
    echo "   ✅ Certificate oluşturuldu"
else
    echo "   ❌ Certificate oluşturulamadı!"
    exit 1
fi
echo ""

echo "5️⃣  Sertifika oluşturulması bekleniyor..."
echo "   ⏳ Bu işlem 1-3 dakika sürebilir..."
echo "   💡 Let's Encrypt'in domain'inizi doğrulaması gerekiyor"
echo ""

for i in {1..90}; do
    CERT_STATUS=$(kubectl get certificate letsencrypt-tls -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
    
    if [ "$CERT_STATUS" = "True" ]; then
        echo "   ✅ Sertifika başarıyla oluşturuldu!"
        break
    elif [ "$CERT_STATUS" = "False" ]; then
        # Order ve Challenge durumunu kontrol et
        ORDER=$(kubectl get order --all-namespaces -o name 2>/dev/null | head -1)
        if [ -n "$ORDER" ]; then
            ORDER_STATE=$(kubectl get $ORDER -o jsonpath='{.status.state}' 2>/dev/null || echo "unknown")
            echo "   ⚠️  Order durumu: $ORDER_STATE"
            
            if [ "$ORDER_STATE" = "invalid" ]; then
                echo "   ❌ Order invalid - challenge başarısız!"
                echo ""
                echo "   Order detayları:"
                kubectl describe $ORDER | tail -30
                echo ""
                echo "   Challenge detayları:"
                kubectl get challenge --all-namespaces
                exit 1
            fi
        fi
        
        # İlk 30 saniye içinde hata verme, bekleniyor olabilir
        if [ $i -gt 15 ]; then
            echo "   ⚠️  Sertifika henüz hazır değil..."
            echo ""
            echo "   Certificate durumu:"
            kubectl get certificate letsencrypt-tls
            echo ""
            echo "   Order durumu:"
            kubectl get order --all-namespaces
            echo ""
            echo "   Challenge durumu:"
            kubectl get challenge --all-namespaces
            echo ""
            echo "   💡 Devam ediyor, bekleniyor... ($i/90)"
        fi
    else
        if [ $((i % 15)) -eq 0 ]; then
            echo "   ⏳ Bekleniyor... ($i/90)"
            kubectl get certificate letsencrypt-tls
        fi
    fi
    sleep 2
done

if [ "$CERT_STATUS" != "True" ]; then
    echo "   ⚠️  Timeout - sertifika henüz hazır değil"
    echo "   💡 Durumu kontrol edin: kubectl get certificate letsencrypt-tls -w"
    echo "   💡 Veya: kubectl describe certificate letsencrypt-tls"
fi
echo ""

echo "6️⃣  Nginx SSL sertifikalarını güncelleniyor..."
if kubectl get secret letsencrypt-tls > /dev/null 2>&1; then
    kubectl get secret letsencrypt-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | sudo tee /etc/nginx/ssl/${DOMAIN}.crt > /dev/null
    kubectl get secret letsencrypt-tls -o jsonpath='{.data.tls\.key}' | base64 -d | sudo tee /etc/nginx/ssl/${DOMAIN}.key > /dev/null
    sudo chmod 600 /etc/nginx/ssl/${DOMAIN}.key
    echo "   ✅ Nginx sertifikaları güncellendi (Let's Encrypt)"
    
    sudo nginx -t && sudo systemctl reload nginx
    echo "   ✅ Nginx reload edildi"
else
    echo "   ⚠️  Secret henüz oluşturulmamış"
    echo "   💡 Birkaç dakika bekleyip tekrar çalıştırın:"
    echo "      kubectl get secret letsencrypt-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | sudo tee /etc/nginx/ssl/${DOMAIN}.crt"
    echo "      kubectl get secret letsencrypt-tls -o jsonpath='{.data.tls\.key}' | base64 -d | sudo tee /etc/nginx/ssl/${DOMAIN}.key"
    echo "      sudo systemctl reload nginx"
fi
echo ""

echo "✅ Let's Encrypt kurulumu tamamlandı!"
echo ""
echo "🌐 Tarayıcıda test edin: https://${DOMAIN}"
echo "   Artık güvenli Let's Encrypt sertifikası görmelisiniz!"
