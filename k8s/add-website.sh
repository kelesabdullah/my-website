#!/bin/bash

# Yeni Website Ekleme Scripti

set -e

echo "🌐 Yeni Website Ekleme"
echo "======================"
echo ""

# Kullanıcıdan bilgi al
read -p "📝 Website adı (örn: my-blog, portfolio): " WEBSITE_NAME
read -p "🌍 Domain adı (örn: blog.example.com): " DOMAIN
read -p "🐳 Docker image adı (örn: kelesabdullah/blog:latest): " DOCKER_IMAGE
read -p "🔌 Container port (varsayılan: 3000): " CONTAINER_PORT
CONTAINER_PORT=${CONTAINER_PORT:-3000}

# Resource limitleri (opsiyonel)
echo ""
echo "💾 Resource Limitleri (Enter ile varsayılan değerleri kullanın):"
read -p "   Memory request (varsayılan: 256Mi): " MEMORY_REQUEST
MEMORY_REQUEST=${MEMORY_REQUEST:-256Mi}
read -p "   Memory limit (varsayılan: 512Mi): " MEMORY_LIMIT
MEMORY_LIMIT=${MEMORY_LIMIT:-512Mi}
read -p "   CPU request (varsayılan: 100m): " CPU_REQUEST
CPU_REQUEST=${CPU_REQUEST:-100m}
read -p "   CPU limit (varsayılan: 500m): " CPU_LIMIT
CPU_LIMIT=${CPU_LIMIT:-500m}

# Env değişkenleri (opsiyonel)
echo ""
read -p "🔧 NODE_ENV eklemek istiyor musunuz? (y/n, varsayılan: y): " ADD_NODE_ENV
ADD_NODE_ENV=${ADD_NODE_ENV:-y}

# Probe ayarları
read -p "⏱️  Probe timeoutSeconds eklemek istiyor musunuz? (y/n, varsayılan: n): " ADD_PROBE_TIMEOUT
ADD_PROBE_TIMEOUT=${ADD_PROBE_TIMEOUT:-n}

if [ -z "$WEBSITE_NAME" ] || [ -z "$DOMAIN" ] || [ -z "$DOCKER_IMAGE" ]; then
    echo "❌ Tüm alanlar doldurulmalı!"
    exit 1
fi

echo ""
echo "📋 Bilgiler:"
echo "   Website Adı: $WEBSITE_NAME"
echo "   Domain: $DOMAIN"
echo "   Docker Image: $DOCKER_IMAGE"
echo "   Container Port: $CONTAINER_PORT"
echo "   Memory: ${MEMORY_REQUEST} / ${MEMORY_LIMIT}"
echo "   CPU: ${CPU_REQUEST} / ${CPU_LIMIT}"
echo ""
read -p "✅ Devam etmek istiyor musunuz? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "❌ İptal edildi"
    exit 1
fi

echo ""
echo "🚀 Website ekleniyor..."
echo ""

# 1. Deployment oluştur
echo "1️⃣  Deployment oluşturuluyor..."

# Deployment YAML'ını geçici dosyaya yaz
DEPLOYMENT_YAML="/tmp/deployment-${WEBSITE_NAME}-$(date +%s).yaml"

cat > "$DEPLOYMENT_YAML" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${WEBSITE_NAME}
  labels:
    app: ${WEBSITE_NAME}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ${WEBSITE_NAME}
  template:
    metadata:
      labels:
        app: ${WEBSITE_NAME}
    spec:
      containers:
      - name: ${WEBSITE_NAME}
        image: ${DOCKER_IMAGE}
        imagePullPolicy: Always
        ports:
        - containerPort: ${CONTAINER_PORT}
          name: http
EOF

# Env değişkenleri ekle
if [ "$ADD_NODE_ENV" = "y" ] || [ "$ADD_NODE_ENV" = "Y" ]; then
    cat >> "$DEPLOYMENT_YAML" <<EOF
        env:
        - name: NODE_ENV
          value: "production"
EOF
fi

# Liveness probe ekle
cat >> "$DEPLOYMENT_YAML" <<EOF
        livenessProbe:
          httpGet:
            path: /
            port: ${CONTAINER_PORT}
          initialDelaySeconds: 30
          periodSeconds: 10
EOF

# Probe timeout ekle
if [ "$ADD_PROBE_TIMEOUT" = "y" ] || [ "$ADD_PROBE_TIMEOUT" = "Y" ]; then
    cat >> "$DEPLOYMENT_YAML" <<EOF
          timeoutSeconds: 3
          failureThreshold: 3
EOF
fi

# Readiness probe ekle
cat >> "$DEPLOYMENT_YAML" <<EOF
        readinessProbe:
          httpGet:
            path: /
            port: ${CONTAINER_PORT}
          initialDelaySeconds: 10
          periodSeconds: 5
EOF

# Probe timeout ekle
if [ "$ADD_PROBE_TIMEOUT" = "y" ] || [ "$ADD_PROBE_TIMEOUT" = "Y" ]; then
    cat >> "$DEPLOYMENT_YAML" <<EOF
          timeoutSeconds: 3
          failureThreshold: 3
EOF
fi

# Resources ekle
cat >> "$DEPLOYMENT_YAML" <<EOF
        resources:
          requests:
            memory: "${MEMORY_REQUEST}"
            cpu: "${CPU_REQUEST}"
          limits:
            memory: "${MEMORY_LIMIT}"
            cpu: "${CPU_LIMIT}"
EOF

# Deployment'ı apply et
kubectl apply -f "$DEPLOYMENT_YAML"
rm -f "$DEPLOYMENT_YAML"

if [ $? -eq 0 ]; then
    echo "   ✅ Deployment oluşturuldu"
else
    echo "   ❌ Deployment oluşturulamadı!"
    exit 1
fi
echo ""

# 2. Service oluştur
echo "2️⃣  Service oluşturuluyor..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ${WEBSITE_NAME}-service
  labels:
    app: ${WEBSITE_NAME}
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: ${CONTAINER_PORT}
    protocol: TCP
    name: http
  selector:
    app: ${WEBSITE_NAME}
EOF

if [ $? -eq 0 ]; then
    echo "   ✅ Service oluşturuldu"
else
    echo "   ❌ Service oluşturulamadı!"
    exit 1
fi
echo ""

# 3. Ingress'e yeni host ekle
echo "3️⃣  Ingress'e yeni host ekleniyor..."
INGRESS_NAME="my-website-ingress"

if ! kubectl get ingress $INGRESS_NAME > /dev/null 2>&1; then
    echo "   ❌ Ingress bulunamadı: $INGRESS_NAME"
    echo "   💡 Önce ./deploy.sh çalıştırın"
    exit 1
fi

# Mevcut ingress'i yedekle
kubectl get ingress $INGRESS_NAME -o yaml > /tmp/ingress-backup-${WEBSITE_NAME}-$(date +%s).yaml

# Ingress'i YAML olarak al ve düzenle
INGRESS_YAML="/tmp/ingress-${WEBSITE_NAME}-$(date +%s).yaml"
kubectl get ingress $INGRESS_NAME -o yaml > "$INGRESS_YAML"

# Başarı flag'i
INGRESS_UPDATED=0

# yq varsa kullan (daha güvenli)
if command -v yq > /dev/null 2>&1; then
    
    # Yeni rule ekle
    yq eval ".spec.rules += [{\"host\": \"${DOMAIN}\", \"http\": {\"paths\": [{\"path\": \"/\", \"pathType\": \"Prefix\", \"backend\": {\"service\": {\"name\": \"${WEBSITE_NAME}-service\", \"port\": {\"number\": 80}}}}]}}]" -i "$INGRESS_YAML" 2>/dev/null
    
    # Apply et
    kubectl apply -f "$INGRESS_YAML" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Ingress güncellendi"
        rm -f "$INGRESS_YAML"
        INGRESS_UPDATED=1
    else
        echo "   ❌ Ingress güncellenemedi!"
        echo "   💡 YAML dosyası: $INGRESS_YAML"
        echo "   💡 Manuel olarak kontrol edip apply edin: kubectl apply -f $INGRESS_YAML"
        exit 1
    fi
elif command -v python3 > /dev/null 2>&1; then
    # Python ile düzenle
    python3 <<PYTHON_SCRIPT
import yaml
import sys
import os

ingress_file = "$INGRESS_YAML"
domain = "$DOMAIN"
service_name = "${WEBSITE_NAME}-service"

try:
    with open(ingress_file, 'r') as f:
        data = yaml.safe_load(f)
    

    
    # Yeni rule ekle
    if 'spec' not in data:
        data['spec'] = {}
    if 'rules' not in data['spec']:
        data['spec']['rules'] = []
    
    new_rule = {
        "host": domain,
        "http": {
            "paths": [{
                "path": "/",
                "pathType": "Prefix",
                "backend": {
                    "service": {
                        "name": service_name,
                        "port": {"number": 80}
                    }
                }
            }]
        }
    }
    
    # Aynı host varsa ekleme
    existing_hosts = [rule.get('host') for rule in data['spec']['rules'] if rule.get('host')]
    if domain not in existing_hosts:
        data['spec']['rules'].append(new_rule)
    
    with open(ingress_file, 'w') as f:
        yaml.dump(data, f, default_flow_style=False, sort_keys=False)
    
    print("OK")
except Exception as e:
    print(f"ERROR: {e}")
    sys.exit(1)
PYTHON_SCRIPT
    
    PYTHON_RESULT=$?
    if [ $PYTHON_RESULT -eq 0 ]; then
        kubectl apply -f "$INGRESS_YAML" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "   ✅ Ingress güncellendi"
            rm -f "$INGRESS_YAML"
            INGRESS_UPDATED=1
        else
            echo "   ❌ Ingress apply edilemedi!"
            echo "   💡 YAML dosyası: $INGRESS_YAML"
            exit 1
        fi
    else
        echo "   ⚠️  Python ile düzenleme başarısız, manuel düzenleme gerekiyor"
        # Fall through to manual editing below
        MANUAL_EDIT_NEEDED=1
    fi
else
    # yq ve python yoksa manuel düzenleme
    MANUAL_EDIT_NEEDED=1
fi

# Manuel düzenleme gerekiyorsa (sadece başarılı olmadıysa)
if [ "$INGRESS_UPDATED" != "1" ]; then
    if [ "${MANUAL_EDIT_NEEDED:-0}" = "1" ] || [ ! -f "$INGRESS_YAML" ] || ! grep -q "${DOMAIN}" "$INGRESS_YAML" 2>/dev/null; then
        echo "   ⚠️  Otomatik düzenleme başarısız, ingress'i manuel olarak düzenlemeniz gerekiyor"
        echo "   💡 Ingress YAML dosyası: $INGRESS_YAML"
        echo ""
        echo "   Şu değişiklikleri yapın:"
        echo "   1. spec.rules listesine şu rule'u ekleyin:"
        echo ""
        cat <<EOF
   - host: ${DOMAIN}
     http:
       paths:
       - path: /
         pathType: Prefix
         backend:
           service:
             name: ${WEBSITE_NAME}-service
             port:
               number: 80
EOF
        echo ""
        echo "   Sonra şu komutu çalıştırın:"
        echo "   kubectl apply -f $INGRESS_YAML"
        echo ""
        read -p "   YAML dosyasını düzenlediniz mi? (y/n): " YAML_EDITED
        
        if [ "$YAML_EDITED" = "y" ] || [ "$YAML_EDITED" = "Y" ]; then
            kubectl apply -f "$INGRESS_YAML"
            if [ $? -eq 0 ]; then
                echo "   ✅ Ingress güncellendi"
                rm -f "$INGRESS_YAML"
            else
                echo "   ❌ Ingress güncellenemedi!"
                echo "   💡 YAML dosyasını kontrol edin: $INGRESS_YAML"
                exit 1
            fi
        else
            echo "   ⚠️  İşlem atlandı, ingress'i manuel olarak güncelleyin"
            echo "   💡 YAML dosyası: $INGRESS_YAML"
            exit 1
        fi
    fi
fi
echo ""

# 4. Nginx proxy'ye ekle
echo "4️⃣  Nginx proxy'ye ekleniyor..."
./add-nginx-site.sh "$DOMAIN"

if [ $? -ne 0 ]; then
    echo "   ⚠️  Nginx proxy eklenemedi, manuel olarak ekleyin"
fi
echo ""

# 5. Let's Encrypt certificate ekle
echo "5️⃣  Let's Encrypt certificate ekleniyor..."
./add-letsencrypt-cert.sh "$DOMAIN"

if [ $? -ne 0 ]; then
    echo "   ⚠️  Certificate eklenemedi, manuel olarak ekleyin"
fi
echo ""

# Durum kontrolü
echo "✅ Website başarıyla eklendi!"
echo ""
echo "📊 Durum:"
kubectl get pods -l app=${WEBSITE_NAME}
echo ""
kubectl get svc -l app=${WEBSITE_NAME}
echo ""
kubectl get ingress $INGRESS_NAME
echo ""
echo "💡 Domain: https://${DOMAIN}"
echo "💡 DNS kaydınızı sunucunuzun public IP'sine yönlendirmeyi unutmayın!"
