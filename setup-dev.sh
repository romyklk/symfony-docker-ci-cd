#!/bin/bash

# Script de configuration pour l'environnement de développement
# Ce script configure l'environnement Docker pour Symfony

set -e

echo "🚀 Configuration de l'environnement de développement Symfony Docker..."

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Vérifier que Docker Compose est installé
if ! command -v docker compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Copier le fichier .env.example vers .env.local s'il n'existe pas
if [ ! -f .env.local ]; then
    echo "📝 Création du fichier .env.local..."
    cp .env.example .env.local
    echo "✅ Fichier .env.local créé. Modifiez-le selon vos besoins."
else
    echo "ℹ️ Le fichier .env.local existe déjà."
fi

# Construire et démarrer les conteneurs
echo "🏗️ Construction des conteneurs Docker..."
docker compose build --no-cache

echo "🚀 Démarrage des services Docker..."
docker compose up -d

# Attendre que les services soient prêts
echo "⏳ Attente que les services soient prêts..."
sleep 10

# Installer les dépendances Composer
echo "📦 Installation des dépendances Composer..."
docker compose exec php composer install --no-interaction

# Créer la base de données
echo "🗄️ Configuration de la base de données..."
docker compose exec php php bin/console doctrine:database:create --if-not-exists
docker compose exec php php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration

# Installer les assets
echo "🎨 Installation des assets..."
docker compose exec php php bin/console asset-map:compile
docker compose exec php php bin/console assets:install

# Effacer le cache
echo "🧹 Nettoyage du cache..."
docker compose exec php php bin/console cache:clear

echo ""
echo "✅ Configuration terminée !"
echo ""
echo "🌐 Accès à l'application :"
echo "   - Application : http://localhost"
echo "   - PHPMyAdmin : http://localhost:8080"
echo ""
echo "📝 Commandes utiles :"
echo "   - Arrêter : docker compose down"
echo "   - Logs : docker compose logs -f"
echo "   - Console Symfony : docker compose exec php php bin/console"
echo ""
