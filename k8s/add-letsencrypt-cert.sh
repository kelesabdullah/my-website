#!/bin/bash

# Let's Encrypt Certificate Ekleme Scripti

set -e

if [ -z "$1" ]; then
    echo "❌ Kullanım: $0 <domain>"
    exit 1
fi

DOMAIN="$1"
SECRET_NAME="letsencrypt-${DOMAIN//./-}-tls"

echo "🔐 Let's Encrypt Certificate Ekleme: $DOMAIN"
echo ""

# ClusterIssuer kontrolü
if ! kubectl get clusterissuer letsencrypt-prod > /dev/null 2>&1; then
    echo "❌ ClusterIssuer 'letsencrypt-prod' bulunamadı!"
    echo "💡 Önce ./setup-letsencrypt.sh çalıştırın"
    exit 1
fi

# Certificate oluştur
echo "📝 Certificate oluşturuluyor..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${SECRET_NAME}
spec:
  secretName: ${SECRET_NAME}
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: ${DOMAIN}
  dnsNames:
  - ${DOMAIN}
EOF

if [ $? -ne 0 ]; then
    echo "❌ Certificate oluşturulamadı!"
    exit 1
fi

echo "✅ Certificate oluşturuldu"
echo ""

# Ingress'e TLS secret ekle
echo "🔧 Ingress'e TLS secret ekleniyor..."
INGRESS_NAME="my-website-ingress"

# TLS host ekle (eğer yoksa)
kubectl patch ingress $INGRESS_NAME --type=json -p="[
  {\"op\": \"add\", \"path\": \"/spec/tls/-\", \"value\": {
    \"hosts\": [\"${DOMAIN}\"],
    \"secretName\": \"${SECRET_NAME}\"
  }}
]" 2>/dev/null || echo "   TLS host zaten mevcut veya eklenemedi"

echo "✅ Ingress güncellendi"
echo ""

# Sertifika oluşturulmasını bekle
echo "⏳ Sertifika oluşturulması bekleniyor..."
echo "   💡 Bu işlem 1-3 dakika sürebilir..."
echo ""

for i in {1..90}; do
    CERT_STATUS=$(kubectl get certificate ${SECRET_NAME} -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
    
    if [ "$CERT_STATUS" = "True" ]; then
        echo "   ✅ Sertifika başarıyla oluşturuldu!"
        break
    elif [ "$CERT_STATUS" = "False" ]; then
        if [ $i -gt 15 ]; then
            echo "   ⚠️  Sertifika henüz hazır değil..."
            ORDER=$(kubectl get order --all-namespaces -o name 2>/dev/null | grep ${SECRET_NAME} | head -1)
            if [ -n "$ORDER" ]; then
                ORDER_STATE=$(kubectl get $ORDER -o jsonpath='{.status.state}' 2>/dev/null || echo "unknown")
                echo "   Order durumu: $ORDER_STATE"
            fi
        fi
    fi
    
    if [ $((i % 15)) -eq 0 ]; then
        echo "   ⏳ Bekleniyor... ($i/90)"
    fi
    sleep 2
done

if [ "$CERT_STATUS" != "True" ]; then
    echo "   ⚠️  Timeout - sertifika henüz hazır değil"
    echo "   💡 Durumu kontrol edin: kubectl get certificate ${SECRET_NAME}"
else
    # Nginx sertifikasını güncelle
    echo ""
    echo "🔄 Nginx sertifikası güncelleniyor..."
    if kubectl get secret ${SECRET_NAME} > /dev/null 2>&1; then
        kubectl get secret ${SECRET_NAME} -o jsonpath='{.data.tls\.crt}' | base64 -d | sudo tee /etc/nginx/ssl/${DOMAIN}.crt > /dev/null
        kubectl get secret ${SECRET_NAME} -o jsonpath='{.data.tls\.key}' | base64 -d | sudo tee /etc/nginx/ssl/${DOMAIN}.key > /dev/null
        sudo chmod 600 /etc/nginx/ssl/${DOMAIN}.key
        echo "   ✅ Nginx sertifikaları güncellendi"
        
        sudo nginx -t && sudo systemctl reload nginx
        echo "   ✅ Nginx yeniden yüklendi"
    fi
fi

echo ""
echo "✅ Certificate işlemi tamamlandı!"
