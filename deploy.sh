#!/bin/bash
set -e  # Stoppe le script si une commande échoue

PROJECT_PATH="/monapp/symfony-docker-ci-cd"

echo "Début du déploiement..."

cd "$PROJECT_PATH"

# Ajout safe.directory pour contourner le problème de propriétaire douteux
git config --global --add safe.directory "$PROJECT_PATH"

# Mettre à jour le code depuis Git (branche production)
git fetch origin production
git reset --hard origin/production

echo "Code mis à jour."

# Redémarrer les services PHP et Nginx
docker-compose -f "$PROJECT_PATH/compose.yaml" restart php nginx

echo "Services redémarrés."

echo "Déploiement terminé avec succès."