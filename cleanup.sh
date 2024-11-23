#!/bin/bash

echo "Suppression de l'Ingress..."
kubectl delete -f fullstack-ingress.yaml

echo "Suppression des configurations de Mailcatcher..."
kubectl delete -f mailcatcher-service.yaml
kubectl delete -f mailcatcher-deployments.yaml

echo "Suppression des configurations d'Adminer..."
kubectl delete -f adminer-service.yaml
kubectl delete -f adminer-deployment.yaml

echo "Suppression des configurations du frontend..."
kubectl delete -f frontend-service.yaml
kubectl delete -f frontend-deployment.yaml

echo "Suppression des configurations du backend..."
kubectl delete -f backend-service.yaml
kubectl delete -f backend-deployment.yaml

echo "Suppression des configurations de la base de données..."
kubectl delete -f db-service.yaml
kubectl delete -f db-deployment.yaml

echo "Suppression des secrets..."
kubectl delete -f postgres-secret.yaml
kubectl delete -f app-secret.yaml

echo "Suppression de Traefik..."
helm uninstall traefik -n kube-system

echo "Nettoyage des fichiers de configuration temporaires..."
rm -f traefik-values.yaml

echo "Toutes les configurations ont été supprimées avec succès!"

