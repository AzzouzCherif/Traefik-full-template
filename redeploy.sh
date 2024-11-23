#!/bin/bash

echo "Ajout du dépôt Helm de Traefik..."
helm repo add traefik https://traefik.github.io/charts
helm repo update

echo "Création du fichier de configuration traefik-values.yaml avec les entryPoints et l'API..."
cat <<EOF > traefik-values.yaml
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
  traefik:
    address: ":8080"

api:
  dashboard: true       # Activer le tableau de bord
  insecure: true        # Autoriser l'accès sans authentification

metrics:
  prometheus:
    enabled: true
    entryPoint: metrics

providers:
  kubernetesCRD:
    enabled: true
  kubernetesIngress:
    enabled: true

log:
  level: INFO           # Niveau de log pour Traefik

accessLog:
  enabled: true         # Activer les logs d'accès
EOF

echo "Déploiement de Traefik avec Helm en utilisant le fichier traefik-values.yaml..."
helm upgrade --install traefik traefik/traefik \
  --namespace kube-system \
  --create-namespace \
  --values traefik-values.yaml \
  --set additionalArguments="{--providers.kubernetescrd,--providers.kubernetescrd.allowEmptyServices=true,--providers.kubernetesingress,--providers.kubernetesingress.allowEmptyServices=true}"

echo "Création de l'IngressRoute pour le tableau de bord Traefik..."
cat <<EOF > traefik-dashboard-ingressroute.yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: traefik-dashboard
  namespace: kube-system
spec:
  entryPoints:
    - traefik
  routes:
    - match: Host(\`traefik.local\`)
      kind: Rule
      services:
        - name: api@internal
          kind: TraefikService
EOF

kubectl apply -f traefik-dashboard-ingressroute.yaml

echo "Ajout de l'entrée /etc/hosts pour traefik.local..."
if ! grep -q "traefik.local" /etc/hosts; then
  echo "127.0.0.1 traefik.local" | sudo tee -a /etc/hosts
fi

echo "Déploiement des secrets..."
kubectl apply -f app-secret.yaml
kubectl apply -f postgres-secret.yaml

echo "Déploiement de la base de données..."
kubectl apply -f db-deployment.yaml
kubectl apply -f db-service.yaml

echo "Déploiement du backend..."
kubectl apply -f backend-deployment.yaml
kubectl apply -f backend-service.yaml

echo "Déploiement du frontend..."
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml

echo "Déploiement d'Adminer..."
kubectl apply -f adminer-deployment.yaml
kubectl apply -f adminer-service.yaml

echo "Déploiement de Mailcatcher..."
kubectl apply -f mailcatcher-deployments.yaml
kubectl apply -f mailcatcher-service.yaml

echo "Configuration de l'Ingress pour les applications..."
kubectl apply -f fullstack-ingress.yaml

echo "Tous les composants ont été déployés avec succès !"

