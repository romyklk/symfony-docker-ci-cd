#!/bin/bash

# Script de pré-déploiement - Force l'environnement de production
# Ce script s'exécute DANS le conteneur Docker

echo "🔧 Configuration de l'environnement de production..."

# Vérifier que nous sommes dans le bon répertoire
cd /var/www || exit 1

# Créer le fichier .env.local pour forcer l'environnement de production
cat > .env.local << EOF
APP_ENV=prod
APP_DEBUG=0
EOF

# Supprimer tous les caches existants
rm -rf var/cache/* var/log/*

echo "✅ Environnement de production configuré"
