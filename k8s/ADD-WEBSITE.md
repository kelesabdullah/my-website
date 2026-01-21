# 🌐 Yeni Website Ekleme Rehberi

Bu rehber, mevcut Minikube ortamınıza yeni bir website eklemeniz için adım adım talimatlar içerir.

## 📋 Gereksinimler

1. ✅ Minikube çalışıyor olmalı
2. ✅ Ingress controller kurulu olmalı
3. ✅ Nginx reverse proxy kurulu olmalı
4. ✅ Cert-Manager ve Let's Encrypt kurulu olmalı
5. ✅ Docker image'ınız hazır olmalı

## 🚀 Hızlı Başlangıç

### Yöntem 1: Otomatik Script (Önerilen)

```bash
cd k8s
chmod +x add-website.sh add-nginx-site.sh add-letsencrypt-cert.sh
./add-website.sh
```

Script size şunları soracak:
- **Website adı**: Kubernetes kaynaklarında kullanılacak isim (örn: `my-blog`)
- **Domain adı**: Website'inizin domain'i (örn: `blog.example.com`)
- **Docker image**: Docker image adınız (örn: `kelesabdullah/blog:latest`)
- **Container port**: Container'ınızın dinlediği port (varsayılan: `3000`, örn: `80`)
- **Resource limitleri**: Memory ve CPU limitleri (Enter ile varsayılan değerleri kullanabilirsiniz)
- **NODE_ENV**: NODE_ENV environment variable eklemek isteyip istemediğiniz
- **Probe timeout**: Probe'lara timeoutSeconds ve failureThreshold eklemek isteyip istemediğiniz

### Yöntem 2: Manuel Adımlar

#### 1. Docker Image Hazırlama

Yeni website'iniz için Docker image oluşturun:

```bash
# Yeni website dizininizde
docker build --platform linux/amd64 -t kelesabdullah/blog:latest .
```

Minikube'da kullanmak için:

```bash
eval $(minikube docker-env)
docker build --platform linux/amd64 -t kelesabdullah/blog:latest .
```

#### 2. Kubernetes Deployment ve Service Oluşturma

`deployment-${WEBSITE_NAME}.yaml` dosyası oluşturun:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-blog
  labels:
    app: my-blog
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-blog
  template:
    metadata:
      labels:
        app: my-blog
    spec:
      containers:
      - name: my-blog
        image: kelesabdullah/blog:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: NODE_ENV
          value: "production"
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

`service-${WEBSITE_NAME}.yaml` dosyası oluşturun:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-blog-service
  labels:
    app: my-blog
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
    name: http
  selector:
    app: my-blog
```

Deploy edin:

```bash
kubectl apply -f deployment-my-blog.yaml
kubectl apply -f service-my-blog.yaml
```

#### 3. Ingress'e Yeni Host Ekleme

Mevcut `ingress.yaml` dosyanızı düzenleyin:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-website-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - kelesabdullah.com
    - blog.example.com  # Yeni domain
    secretName: letsencrypt-tls
  - hosts:
    - blog.example.com  # Yeni domain için ayrı TLS
    secretName: letsencrypt-blog-example-com-tls
  rules:
  - host: kelesabdullah.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-website-service
            port:
              number: 80
  - host: blog.example.com  # Yeni domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-blog-service
            port:
              number: 80
```

Güncelleyin:

```bash
kubectl apply -f ingress.yaml
```

#### 4. Nginx Reverse Proxy'ye Ekleme

```bash
./add-nginx-site.sh blog.example.com
```

Veya manuel olarak `/etc/nginx/sites-available/blog.example.com` dosyası oluşturun.

#### 5. Let's Encrypt Certificate Ekleme

```bash
./add-letsencrypt-cert.sh blog.example.com
```

#### 6. DNS Yapılandırması

DNS kaydınızı sunucunuzun public IP'sine yönlendirin:

```
A Record: blog.example.com → <sunucu-public-ip>
```

## ✅ Kontrol

```bash
# Pod durumu
kubectl get pods -l app=my-blog

# Service durumu
kubectl get svc my-blog-service

# Ingress durumu
kubectl get ingress my-website-ingress

# Certificate durumu
kubectl get certificate letsencrypt-blog-example-com-tls

# Test
curl -I https://blog.example.com
```

## 🔧 Sorun Giderme

### Pod çalışmıyor

```bash
kubectl describe pod -l app=my-blog
kubectl logs -l app=my-blog
```

### Service erişilemiyor

```bash
kubectl get endpoints my-blog-service
kubectl describe service my-blog-service
```

### Ingress çalışmıyor

```bash
kubectl describe ingress my-website-ingress
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### SSL sertifikası oluşturulmuyor

```bash
kubectl describe certificate letsencrypt-blog-example-com-tls
kubectl get order --all-namespaces
kubectl get challenge --all-namespaces
```

### Nginx 502 hatası

```bash
sudo tail -f /var/log/nginx/error.log
kubectl get svc ingress-nginx-controller -n ingress-nginx
```

## 📝 Örnek Senaryolar

### Senaryo 1: Next.js Blog (Port 3000)

```bash
# 1. Blog projesini Dockerize et
cd ~/my-blog
docker build --platform linux/amd64 -t kelesabdullah/blog:latest .

# 2. Minikube'da build et
eval $(minikube docker-env)
docker build --platform linux/amd64 -t kelesabdullah/blog:latest .

# 3. Website ekle
cd ~/my-website/k8s
./add-website.sh
# Website adı: my-blog
# Domain: blog.kelesabdullah.com
# Docker image: kelesabdullah/blog:latest
# Container port: 3000 (Enter ile varsayılan)
# Resource limitleri: Enter ile varsayılanları kullan
# NODE_ENV: y
# Probe timeout: n
```

### Senaryo 2: Static Website (Port 80, Düşük Kaynak)

```bash
# 1. Website'i Dockerize et
cd ~/prensesi-koru
docker build --platform linux/amd64 -t kelesabdullah/website:prensesi-koru .

# 2. Minikube'da build et
eval $(minikube docker-env)
docker build --platform linux/amd64 -t kelesabdullah/website:prensesi-koru .

# 3. Website ekle
cd ~/my-website/k8s
./add-website.sh
# Website adı: prensesi-koru
# Domain: prensesi-koru.kelesabdullah.com
# Docker image: kelesabdullah/website:prensesi-koru
# Container port: 80
# Memory request: 64Mi
# Memory limit: 128Mi
# CPU request: 100m
# CPU limit: 200m
# NODE_ENV: n (static website için gerekli değil)
# Probe timeout: y (timeoutSeconds ve failureThreshold ekle)
```

### Senaryo 2: Static Website

Static website için container port'u 80 olabilir. Service'i buna göre ayarlayın:

```yaml
spec:
  ports:
  - port: 80
    targetPort: 80  # Container port
```

## 💡 İpuçları

1. **Aynı Ingress kullanın**: Tüm website'leriniz için tek bir Ingress kullanabilirsiniz
2. **Farklı namespace'ler**: Her website için ayrı namespace kullanabilirsiniz
3. **Resource limits**: Her website için uygun resource limitleri ayarlayın
4. **Monitoring**: Pod ve service'lerin durumunu düzenli kontrol edin

## 🗑️ Website Silme

### Otomatik Script (Önerilen)

```bash
cd k8s
./remove-website.sh
```

Script size şunları soracak:
- **Website adı**: Silinecek website'in Kubernetes'teki adı (örn: `my-blog`)
- **Domain adı**: Silinecek domain (örn: `blog.example.com`)

Script şunları yapar:
- ✅ Kubernetes Deployment'ı siler
- ✅ Kubernetes Service'i siler
- ✅ Ingress'ten host'u kaldırır
- ✅ Certificate'i siler
- ✅ Nginx config'ini siler
- ✅ Nginx'i reload eder

### Manuel Silme

```bash
# Kubernetes kaynaklarını sil
kubectl delete deployment my-blog
kubectl delete service my-blog-service

# Certificate'i sil
kubectl delete certificate letsencrypt-blog-example-com-tls

# Ingress'ten host'u kaldır (yq gerekli)
kubectl get ingress my-website-ingress -o yaml | \
  yq eval "del(.spec.tls[] | select(.hosts[] == \"blog.example.com\"))" - | \
  yq eval "del(.spec.rules[] | select(.host == \"blog.example.com\"))" - | \
  kubectl apply -f -

# Nginx config'i sil
sudo rm /etc/nginx/sites-enabled/blog.example.com
sudo rm /etc/nginx/sites-available/blog.example.com
sudo systemctl reload nginx
```
