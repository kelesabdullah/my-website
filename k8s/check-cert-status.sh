#!/bin/bash

echo "🔍 Let's Encrypt Sertifika Durumu Kontrolü"
echo "=========================================="
echo ""

echo "1️⃣ Certificate durumu:"
kubectl get certificate letsencrypt-tls -o wide
echo ""

echo "2️⃣ Certificate detayları:"
kubectl describe certificate letsencrypt-tls | tail -40
echo ""

echo "3️⃣ CertificateRequest durumu:"
kubectl get certificaterequest --all-namespaces
echo ""

echo "4️⃣ Order durumu:"
kubectl get order --all-namespaces
if [ $? -eq 0 ]; then
    ORDER=$(kubectl get order --all-namespaces -o name 2>/dev/null | head -1)
    if [ -n "$ORDER" ]; then
        echo ""
        echo "   Order detayları:"
        kubectl describe $ORDER | tail -30
    fi
fi
echo ""

echo "5️⃣ Challenge durumu:"
kubectl get challenge --all-namespaces
CHALLENGE=$(kubectl get challenge --all-namespaces -o name 2>/dev/null | head -1)
if [ -n "$CHALLENGE" ]; then
    echo ""
    echo "   Challenge detayları:"
    kubectl describe $CHALLENGE | tail -40
fi
echo ""

echo "6️⃣ ClusterIssuer durumu:"
kubectl get clusterissuer letsencrypt-prod
echo ""

echo "7️⃣ Ingress durumu:"
kubectl get ingress my-website-ingress
echo ""

echo "8️⃣ Cert-Manager pod logları (son 20 satır):"
kubectl logs -n cert-manager -l app=cert-manager --tail=20
