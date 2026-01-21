#!/bin/bash

# Nginx'e Yeni Site Ekleme Scripti

set -e

if [ -z "$1" ]; then
    echo "❌ Kullanım: $0 <domain>"
    exit 1
fi

DOMAIN="$1"

echo "🔧 Nginx'e yeni site ekleniyor: $DOMAIN"
echo ""

# Minikube IP'sini al
MINIKUBE_IP=$(minikube ip 2>/dev/null)
if [ -z "$MINIKUBE_IP" ]; then
    echo "❌ Minikube IP alınamadı! Minikube çalışıyor mu kontrol edin."
    exit 1
fi

# NodePort'u öğren
HTTP_NODEPORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}' 2>/dev/null)

if [ -z "$HTTP_NODEPORT" ]; then
    echo "❌ HTTP NodePort bulunamadı!"
    exit 1
fi

# Nginx config oluştur
CONFIG_FILE="/etc/nginx/sites-available/${DOMAIN}"

if [ -f "$CONFIG_FILE" ]; then
    echo "⚠️  Config dosyası zaten mevcut: $CONFIG_FILE"
    read -p "Üzerine yazmak istiyor musunuz? (y/n): " OVERWRITE
    if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
        echo "❌ İptal edildi"
        exit 1
    fi
fi

echo "📝 Nginx config dosyası oluşturuluyor..."
sudo tee $CONFIG_FILE > /dev/null <<EOF
# HTTP -> HTTPS redirect
server {
    listen 80;
    server_name ${DOMAIN};
    
    # Let's Encrypt challenge için ingress controller'a yönlendir
    location /.well-known/acme-challenge/ {
        proxy_pass http://${MINIKUBE_IP}:${HTTP_NODEPORT};
        proxy_set_header Host \$host;
    }
    
    # Diğer tüm istekleri HTTPS'e yönlendir
    location / {
        return 301 https://\$host\$request_uri;
    }
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    
    # SSL sertifikaları (Let's Encrypt)
    ssl_certificate /etc/nginx/ssl/${DOMAIN}.crt;
    ssl_certificate_key /etc/nginx/ssl/${DOMAIN}.key;
    
    # SSL ayarları
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Proxy ayarları
    location / {
        proxy_pass http://${MINIKUBE_IP}:${HTTP_NODEPORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        # WebSocket desteği
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeout ayarları
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

echo "✅ Config dosyası oluşturuldu: $CONFIG_FILE"
echo ""

# SSL dizini oluştur
sudo mkdir -p /etc/nginx/ssl

# Geçici self-signed sertifika oluştur
if [ ! -f "/etc/nginx/ssl/${DOMAIN}.crt" ]; then
    echo "🔐 Geçici self-signed SSL sertifikası oluşturuluyor..."
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/${DOMAIN}.key \
        -out /etc/nginx/ssl/${DOMAIN}.crt \
        -subj "/C=TR/ST=Istanbul/L=Istanbul/O=MyCompany/CN=${DOMAIN}" \
        -addext "subjectAltName=DNS:${DOMAIN}"
    sudo chmod 600 /etc/nginx/ssl/${DOMAIN}.key
    echo "✅ Geçici sertifika oluşturuldu"
else
    echo "✅ SSL sertifikası zaten mevcut"
fi
echo ""

# Site'ı aktif et
echo "🔗 Site aktif ediliyor..."
sudo ln -sf $CONFIG_FILE /etc/nginx/sites-enabled/
echo "✅ Site aktif edildi"
echo ""

# Nginx config test
echo "🧪 Nginx config test ediliyor..."
sudo nginx -t
if [ $? -ne 0 ]; then
    echo "❌ Nginx config hatası!"
    exit 1
fi
echo "✅ Nginx config doğru"
echo ""

# Nginx'i yeniden yükle
echo "🔄 Nginx yeniden yükleniyor..."
sudo systemctl reload nginx
echo "✅ Nginx yeniden yüklendi"
echo ""

echo "✅ Nginx site eklendi: $DOMAIN"
