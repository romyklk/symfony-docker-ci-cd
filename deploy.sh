#!/bin/bash
set -e  # Stoppe le script si une commande échoue

PROJECT_PATH="/monapp/symfony-docker-ci-cd"
CONTAINER_PHP="symfony-docker-ci-cd_php_1"
CONTAINER_NGINX="symfony-docker-ci-cd_nginx_1"

echo "Début du déploiement..."

# Se positionner dans le dossier projet
cd "$PROJECT_PATH"

# Mettre à jour le code depuis Git (branche production)
git fetch origin production
git reset --hard origin/production

echo "Code mis à jour."

# Redémarrer les services PHP et Nginx
docker-compose -f "$PROJECT_PATH/compose.yaml" restart php nginx

echo "Services redémarrés."

echo "Déploiement terminé avec succès."
# Fin du script