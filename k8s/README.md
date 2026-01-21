# Kubernetes Deployment Rehberi

Bu rehber, `kelesabdullah.com` domain'i için website'inizi Minikube üzerinde Let's Encrypt SSL sertifikası ile deploy etmek için gerekli adımları içerir.

## Mimari

```
Internet → Nginx (443 HTTPS) → Ingress Controller (80 HTTP) → Service → Pod
         [Let's Encrypt]      [NodePort]
```

## Ön Gereksinimler

- Minikube kurulu
- kubectl kurulu
- Docker kurulu
- Domain: `kelesabdullah.com`
- DNS kaydı erişimi
- Sunucuda sudo erişimi

## Adım Adım Kurulum

### 1. VM Ortamını Temizleme (İlk Kurulum Öncesi)

```bash
cd k8s
./cleanup-all.sh
```

Detaylı temizleme rehberi: `CLEANUP.md`

### 2. Kubernetes Deployment

```bash
cd k8s
chmod +x *.sh
./deploy.sh
```

Bu script:
- Minikube'u başlatır (gerekirse)
- Ingress controller'ı kurar
- Docker image'ı build eder (linux/amd64)
- Kubernetes kaynaklarını deploy eder

### 3. Nginx Reverse Proxy

```bash
./setup-nginx-proxy.sh
```

Bu script:
- Nginx'i kurar
- Ingress controller'ın NodePort'una proxy yapan config oluşturur
- ACME challenge için özel location ekler
- Geçici self-signed sertifika oluşturur
- Nginx'i başlatır

### 4. DNS Yapılandırması

DNS kayıtlarınızı sunucunuzun **public IP adresine** yönlendirin:

```
A Record: kelesabdullah.com → <sunucu-public-ip>
```

Public IP'yi öğrenmek için:
```bash
curl ifconfig.me
```

### 5. Let's Encrypt SSL Sertifikası

```bash
./setup-letsencrypt.sh
```

Bu script:
- Cert-manager'ı kurar
- ClusterIssuer oluşturur
- Certificate oluşturur (sadece `kelesabdullah.com`, wildcard yok)
- Let's Encrypt challenge'ını bekler
- Nginx sertifikalarını günceller

**Önemli:** Port 80 açık olmalı (Let's Encrypt HTTP-01 challenge için):
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### 6. Test

```bash
# Localhost test
curl -k -I https://localhost -H "Host: kelesabdullah.com"

# Domain test (DNS propagasyonu sonrası)
curl -k -I https://kelesabdullah.com
```

Tarayıcıda: `https://kelesabdullah.com`

## Yeni Website Ekleme

Aynı Minikube ortamına yeni bir website eklemek için:

```bash
cd k8s
./add-website.sh
```

Script size şunları soracak:
- Website adı (örn: `my-blog`)
- Domain adı (örn: `blog.kelesabdullah.com`)
- Docker image (örn: `kelesabdullah/blog:latest`)

Detaylı rehber: `ADD-WEBSITE.md`

## Website Silme

Eklenmiş bir website'i silmek için:

```bash
cd k8s
./remove-website.sh
```

Script size şunları soracak:
- Website adı (örn: `my-blog`)
- Domain adı (örn: `blog.kelesabdullah.com`)

Script otomatik olarak:
- ✅ Kubernetes kaynaklarını siler
- ✅ Ingress'ten host'u kaldırır
- ✅ Certificate'i siler
- ✅ Nginx config'ini temizler

## Dosya Yapısı

```
k8s/
├── deployment.yaml          # Kubernetes deployment
├── service.yaml             # Kubernetes service
├── ingress.yaml             # Kubernetes ingress (Let's Encrypt için yapılandırılmış)
├── deploy.sh                # Kubernetes deployment scripti
├── setup-nginx-proxy.sh     # Nginx reverse proxy kurulumu
├── setup-letsencrypt.sh     # Let's Encrypt SSL sertifikası kurulumu
├── add-website.sh           # Yeni website ekleme scripti
├── add-nginx-site.sh        # Nginx'e yeni site ekleme
├── add-letsencrypt-cert.sh  # Let's Encrypt certificate ekleme
├── remove-website.sh         # Website silme scripti
├── cleanup-all.sh           # Tüm ortamı temizleme scripti
├── README.md                # Bu dosya
├── ADD-WEBSITE.md           # Yeni website ekleme rehberi
└── CLEANUP.md               # Temizleme rehberi
```

## Önemli Notlar

- **Domain**: `kelesabdullah.com` (hardcoded, değiştirmek için script'leri düzenleyin)
- **Wildcard yok**: Sadece normal domain için sertifika (HTTP-01 challenge)
- **Minikube IP**: Ingress controller'ın NodePort'una erişmek için kullanılır
- **DNS**: Public IP'ye yönlendirin, Minikube IP'sine değil
- **Firewall**: 80 ve 443 portları açık olmalı

## Troubleshooting

### Website açılmıyor

```bash
# Pod durumu
kubectl get pods -l app=my-website

# Service durumu
kubectl get svc

# Ingress durumu
kubectl get ingress

# Nginx durumu
sudo systemctl status nginx

# Nginx log'ları
sudo tail -f /var/log/nginx/error.log
```

### SSL sertifikası oluşturulmuyor

```bash
# Certificate durumu
kubectl get certificate letsencrypt-tls

# CertificateRequest durumu
kubectl get certificaterequest

# Order durumu
kubectl get order --all-namespaces

# Challenge durumu
kubectl get challenge --all-namespaces

# Detaylı bilgi
kubectl describe certificate letsencrypt-tls
```

**Yaygın sorunlar:**
- Port 80 kapalı → `sudo ufw allow 80/tcp`
- DNS kaydı yanlış → `nslookup kelesabdullah.com`
- ACME challenge erişilemiyor → Nginx config'i kontrol edin

### DNS çalışmıyor

- DNS propagasyonu 5-30 dakika sürebilir
- `nslookup kelesabdullah.com` ile kontrol edin
- Farklı DNS sunucularından test edin: `dig @8.8.8.8 kelesabdullah.com`

## Kaynakları Silme

```bash
cd k8s
./cleanup-all.sh
```

Veya manuel olarak:

```bash
kubectl delete -f ingress.yaml
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
kubectl delete certificate letsencrypt-tls
kubectl delete clusterissuer letsencrypt-prod
kubectl delete namespace cert-manager
```

## Yeni Ortama Taşıma

1. Bu rehberi baştan takip edin
2. Script'lerde domain adı zaten `kelesabdullah.com` olarak ayarlı
3. DNS kayıtlarını yeni sunucunun public IP'sine yönlendirin
