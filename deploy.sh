#!/bin/bash

# Script de déploiement pour l'environnement de production
# Ce script s'exécute DANS le conteneur Docker

set -e  # Arrêter en cas d'erreur

echo "🚀 Début du déploiement en production..."

# Vérifier que nous sommes dans le bon répertoire
cd /var/www || exit 1

# Définir les variables d'environnement
export APP_ENV=prod
export APP_DEBUG=0

echo "🧹 Nettoyage complet du cache..."
rm -rf var/cache/prod var/cache/dev var/log/*.log

echo "📦 Installation des dépendances..."
composer install --no-dev --optimize-autoloader --no-scripts

echo "🗄️ Mise à jour de la base de données..."
php bin/console doctrine:database:create --if-not-exists --env=prod
php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration --env=prod

echo "🎨 Compilation des assets..."
php bin/console asset-map:compile --env=prod

echo "📁 Installation des assets web..."
php bin/console assets:install --symlink --relative --env=prod

echo "📦 Installation de l'importmap..."
php bin/console importmap:install --env=prod

echo "🧹 Nettoyage et réchauffement du cache..."
php bin/console cache:clear --env=prod
php bin/console cache:warmup --env=prod

echo "✅ Déploiement terminé avec succès !"
