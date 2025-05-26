#!/bin/bash

# Script de déploiement complet pour l'environnement de production
# Ce script s'exécute ENTIÈREMENT dans le conteneur Docker

set -e  # Arrêter en cas d'erreur

echo "🚀 Début du déploiement complet en production..."

# Vérifier que nous sommes dans le bon répertoire
cd /var/www || exit 1

echo "🔧 Configuration de l'environnement de production..."

# Forcer l'environnement de production via .env.local
cat > .env.local << EOF
APP_ENV=prod
APP_DEBUG=0
EOF

echo "🧹 Nettoyage complet des fichiers temporaires..."
rm -rf var/cache/* var/log/* vendor composer.lock

echo "📦 Installation des dépendances de production..."
composer install --no-dev --optimize-autoloader --no-scripts

echo "🗄️ Mise à jour de la base de données..."
APP_ENV=prod php bin/console doctrine:database:create --if-not-exists
APP_ENV=prod php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration

echo "🎨 Compilation des assets..."
APP_ENV=prod php bin/console asset-map:compile

echo "📁 Installation des assets web..."
APP_ENV=prod php bin/console assets:install --symlink --relative

echo "📦 Installation de l'importmap..."
APP_ENV=prod php bin/console importmap:install

echo "🧹 Nettoyage et réchauffement du cache de production..."
APP_ENV=prod php bin/console cache:clear
APP_ENV=prod php bin/console cache:warmup

echo "🔒 Correction des permissions finales..."
chown -R www-data:www-data /var/www/var

echo "✅ Déploiement complet terminé avec succès !"
echo "🌐 L'application est maintenant en mode production"
