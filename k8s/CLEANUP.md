# VM Ortamını Temizleme Rehberi

Bu rehber, VM'deki tüm Kubernetes ve Nginx kaynaklarını temizlemek için adımları içerir.

## 1. Kubernetes Kaynaklarını Temizleme

```bash
# Tüm deployment, service ve ingress'i sil
kubectl delete ingress my-website-ingress 2>/dev/null || true
kubectl delete service my-website-service 2>/dev/null || true
kubectl delete deployment my-website 2>/dev/null || true

# Certificate ve ilgili kaynakları sil
kubectl delete certificate letsencrypt-tls 2>/dev/null || true
kubectl delete certificaterequest --all 2>/dev/null || true
kubectl delete order --all-namespaces --all 2>/dev/null || true
kubectl delete challenge --all-namespaces --all 2>/dev/null || true
kubectl delete secret letsencrypt-tls 2>/dev/null || true
kubectl delete secret wildcard-tls 2>/dev/null || true

# ClusterIssuer'ı sil
kubectl delete clusterissuer letsencrypt-prod 2>/dev/null || true

# Cert-manager'ı sil
kubectl delete namespace cert-manager 2>/dev/null || true
```

## 2. Nginx Temizleme

```bash
# Nginx config dosyasını sil
sudo rm -f /etc/nginx/sites-enabled/kelesabdullah.com
sudo rm -f /etc/nginx/sites-available/kelesabdullah.com

# SSL sertifikalarını sil
sudo rm -rf /etc/nginx/ssl/kelesabdullah.com.*

# Nginx'i reload et
sudo systemctl reload nginx
```

## 3. Minikube Temizleme (Opsiyonel)

Eğer Minikube'u da tamamen temizlemek istiyorsanız:

```bash
# Minikube'u durdur ve sil
minikube stop
minikube delete

# Minikube config'ini temizle
rm -rf ~/.minikube
```

## 4. Docker Temizleme (Opsiyonel)

```bash
# Kullanılmayan image'ları temizle
docker image prune -a

# Kullanılmayan container'ları temizle
docker container prune
```

## 5. Tüm Kaynakları Kontrol Etme

```bash
# Kubernetes kaynaklarını kontrol et
kubectl get all
kubectl get ingress
kubectl get certificate --all-namespaces
kubectl get secret

# Nginx config'lerini kontrol et
ls -la /etc/nginx/sites-enabled/
ls -la /etc/nginx/sites-available/
ls -la /etc/nginx/ssl/
```

## Hızlı Temizleme Scripti

Tüm yukarıdaki adımları otomatik yapan script:

```bash
cd k8s
./cleanup-all.sh
```
