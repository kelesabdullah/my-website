#!/bin/bash

# Website Silme Scripti

set -e

echo "🗑️  Website Silme"
echo "=================="
echo ""

# Kullanıcıdan bilgi al
read -p "📝 Silinecek website adı (örn: my-blog): " WEBSITE_NAME
read -p "🌍 Domain adı (örn: blog.kelesabdullah.com): " DOMAIN

if [ -z "$WEBSITE_NAME" ] || [ -z "$DOMAIN" ]; then
    echo "❌ Tüm alanlar doldurulmalı!"
    exit 1
fi

echo ""
echo "⚠️  UYARI: Aşağıdaki kaynaklar silinecek:"
echo "   - Deployment: ${WEBSITE_NAME}"
echo "   - Service: ${WEBSITE_NAME}-service"
echo "   - Domain: ${DOMAIN}"
echo "   - Certificate: letsencrypt-${DOMAIN//./-}-tls"
echo "   - Nginx config: /etc/nginx/sites-available/${DOMAIN}"
echo ""
read -p "✅ Devam etmek istiyor musunuz? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "❌ İptal edildi"
    exit 1
fi

echo ""
echo "🗑️  Website siliniyor..."
echo ""

# 1. Deployment'ı sil
echo "1️⃣  Deployment siliniyor..."
if kubectl get deployment ${WEBSITE_NAME} > /dev/null 2>&1; then
    kubectl delete deployment ${WEBSITE_NAME}
    echo "   ✅ Deployment silindi"
else
    echo "   ⚠️  Deployment bulunamadı (zaten silinmiş olabilir)"
fi
echo ""

# 2. Service'i sil
echo "2️⃣  Service siliniyor..."
if kubectl get service ${WEBSITE_NAME}-service > /dev/null 2>&1; then
    kubectl delete service ${WEBSITE_NAME}-service
    echo "   ✅ Service silindi"
else
    echo "   ⚠️  Service bulunamadı (zaten silinmiş olabilir)"
fi
echo ""

# 3. Ingress'ten host'u kaldır
echo "3️⃣  Ingress'ten host kaldırılıyor..."
INGRESS_NAME="my-website-ingress"

if kubectl get ingress ${INGRESS_NAME} > /dev/null 2>&1; then
    # Rule'u kaldır
    RULE_INDEX=$(kubectl get ingress ${INGRESS_NAME} -o jsonpath="{.spec.rules[?(@.host=='${DOMAIN}')].host}" 2>/dev/null | wc -l)
    
    if [ "$RULE_INDEX" -gt 0 ]; then
        # Rule index'ini bul
        RULE_COUNT=0
        FOUND_INDEX=-1
        for i in $(kubectl get ingress ${INGRESS_NAME} -o jsonpath='{.spec.rules[*].host}'); do
            if [ "$i" = "$DOMAIN" ]; then
                FOUND_INDEX=$RULE_COUNT
                break
            fi
            RULE_COUNT=$((RULE_COUNT + 1))
        done
        
        if [ $FOUND_INDEX -ge 0 ]; then
            kubectl patch ingress ${INGRESS_NAME} --type=json -p="[
                {\"op\": \"remove\", \"path\": \"/spec/rules/${FOUND_INDEX}\"}
            ]" 2>/dev/null && echo "   ✅ Ingress rule kaldırıldı" || echo "   ⚠️  Ingress rule kaldırılamadı"
        fi
    else
        echo "   ⚠️  Ingress'te bu domain bulunamadı"
    fi
    
    # TLS host'u kaldır
    # Ingress'i YAML olarak al ve domain'i içeren TLS entry'lerini kaldır
    INGRESS_YAML=$(kubectl get ingress ${INGRESS_NAME} -o yaml 2>/dev/null)
    
    if echo "$INGRESS_YAML" | grep -q "${DOMAIN}"; then
        # yq varsa kullan (daha güvenli)
        if command -v yq > /dev/null 2>&1; then
            kubectl get ingress ${INGRESS_NAME} -o yaml | \
            yq eval "del(.spec.tls[] | select(.hosts[] == \"${DOMAIN}\"))" - | \
            yq eval "del(.spec.rules[] | select(.host == \"${DOMAIN}\"))" - | \
            kubectl apply -f - > /dev/null 2>&1 && echo "   ✅ Ingress TLS ve rule kaldırıldı" || echo "   ⚠️  Ingress güncellenemedi"
        else
            # yq yoksa, ingress'i YAML olarak al, düzenle ve apply et
            echo "   ⚠️  yq bulunamadı, ingress'i manuel olarak düzenlemeniz gerekiyor"
            TEMP_FILE="/tmp/ingress-${DOMAIN}-$(date +%s).yaml"
            kubectl get ingress ${INGRESS_NAME} -o yaml > "$TEMP_FILE"
            echo "   💡 Ingress YAML dosyası oluşturuldu: $TEMP_FILE"
            echo "   💡 Bu dosyadan '${DOMAIN}' içeren TLS ve rule'ları silin"
            echo "   💡 Sonra şu komutu çalıştırın: kubectl apply -f $TEMP_FILE"
            echo ""
            echo "   Veya ingress.yaml dosyasını düzenleyin ve şu domain'i kaldırın: ${DOMAIN}"
            echo "   Sonra: kubectl apply -f ingress.yaml"
        fi
    else
        echo "   ⚠️  Ingress'te bu domain bulunamadı"
    fi
else
    echo "   ⚠️  Ingress bulunamadı"
fi
echo ""

# 4. Certificate'i sil
echo "4️⃣  Certificate siliniyor..."
SECRET_NAME="letsencrypt-${DOMAIN//./-}-tls"

if kubectl get certificate ${SECRET_NAME} > /dev/null 2>&1; then
    kubectl delete certificate ${SECRET_NAME}
    echo "   ✅ Certificate silindi"
else
    echo "   ⚠️  Certificate bulunamadı (zaten silinmiş olabilir)"
fi

# Secret'ı da sil (eğer varsa)
if kubectl get secret ${SECRET_NAME} > /dev/null 2>&1; then
    kubectl delete secret ${SECRET_NAME}
    echo "   ✅ Secret silindi"
fi
echo ""

# 5. Nginx config'i sil
echo "5️⃣  Nginx config siliniyor..."
NGINX_CONFIG="/etc/nginx/sites-available/${DOMAIN}"
NGINX_ENABLED="/etc/nginx/sites-enabled/${DOMAIN}"

if [ -f "$NGINX_ENABLED" ] || [ -L "$NGINX_ENABLED" ]; then
    sudo rm -f "$NGINX_ENABLED"
    echo "   ✅ Nginx enabled link silindi"
fi

if [ -f "$NGINX_CONFIG" ]; then
    sudo rm -f "$NGINX_CONFIG"
    echo "   ✅ Nginx config silindi"
else
    echo "   ⚠️  Nginx config bulunamadı (zaten silinmiş olabilir)"
fi

# SSL sertifikalarını sil (opsiyonel)
read -p "🔐 SSL sertifikalarını da silmek istiyor musunuz? (y/n): " DELETE_SSL
if [ "$DELETE_SSL" = "y" ] || [ "$DELETE_SSL" = "Y" ]; then
    if [ -f "/etc/nginx/ssl/${DOMAIN}.crt" ]; then
        sudo rm -f "/etc/nginx/ssl/${DOMAIN}.crt"
        echo "   ✅ SSL certificate silindi"
    fi
    if [ -f "/etc/nginx/ssl/${DOMAIN}.key" ]; then
        sudo rm -f "/etc/nginx/ssl/${DOMAIN}.key"
        echo "   ✅ SSL key silindi"
    fi
fi
echo ""

# 6. Nginx'i reload et
echo "6️⃣  Nginx yeniden yükleniyor..."
sudo nginx -t > /dev/null 2>&1
if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    echo "   ✅ Nginx yeniden yüklendi"
else
    echo "   ⚠️  Nginx config hatası, reload edilemedi"
    echo "   💡 Manuel olarak kontrol edin: sudo nginx -t"
fi
echo ""

# Durum kontrolü
echo "✅ Website silme işlemi tamamlandı!"
echo ""
echo "📊 Kalan kaynaklar:"
kubectl get pods 2>/dev/null | grep -v "${WEBSITE_NAME}" || echo "   (Pod yok)"
kubectl get svc 2>/dev/null | grep -v "${WEBSITE_NAME}" || echo "   (Service yok)"
echo ""
kubectl get ingress ${INGRESS_NAME} 2>/dev/null || echo "   Ingress bulunamadı"
echo ""
echo "💡 İşlem tamamlandı!"
