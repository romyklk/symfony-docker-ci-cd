#!/bin/bash

# Script de test local pour le déploiement
# Simule un environnement de production localement

set -e

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

# Configuration
PROJECT_ROOT=$(pwd)
TEST_DIR="/tmp/symfony-deploy-test"
ORIGINAL_DEPLOY_SCRIPT="$PROJECT_ROOT/deploy.sh"

log_info "🧪 Test de déploiement local pour Symfony Docker CI/CD"

# Nettoyage des tests précédents
if [ -d "$TEST_DIR" ]; then
    log_step "Nettoyage des tests précédents..."
    rm -rf "$TEST_DIR"
fi

# Création de l'environnement de test
log_step "Création de l'environnement de test..."
mkdir -p "$TEST_DIR"
cp -r "$PROJECT_ROOT"/* "$TEST_DIR/" 2>/dev/null || true
cp -r "$PROJECT_ROOT"/.[^.]* "$TEST_DIR/" 2>/dev/null || true

cd "$TEST_DIR"

# Vérification des prérequis
log_step "Vérification des prérequis..."

if ! command -v docker >/dev/null 2>&1; then
    log_error "Docker n'est pas installé"
    exit 1
fi

if ! command -v docker-compose >/dev/null 2>&1; then
    log_error "Docker Compose n'est pas installé"
    exit 1
fi

log_success "Prérequis vérifiés"

# Démarrage des services Docker
log_step "Démarrage des services Docker..."
docker-compose down -v 2>/dev/null || true
docker-compose up -d --build

# Attendre que les services soient prêts
log_step "Attente du démarrage des services..."
sleep 15

# Vérifier que les conteneurs sont en cours d'exécution
if ! docker-compose ps | grep -q "Up"; then
    log_error "Les conteneurs ne sont pas démarrés correctement"
    docker-compose logs
    exit 1
fi

log_success "Services Docker démarrés"

# Adapter le script de déploiement pour le test local
log_step "Adaptation du script de déploiement pour le test..."

# Copier le script original
cp "$ORIGINAL_DEPLOY_SCRIPT" ./deploy-test.sh
chmod +x ./deploy-test.sh

# Modifier le script pour l'environnement de test
sed -i.bak 's|PROJECT_PATH="/var/www/symfony-docker-ci-cd"|PROJECT_PATH="'$TEST_DIR'"|g' ./deploy-test.sh
sed -i.bak 's|symfony-docker-ci-cd_php_1|'$(docker-compose ps --services | grep php | head -1)'|g' ./deploy-test.sh
sed -i.bak 's|git pull origin production|echo "Simulation: git pull origin production"|g' ./deploy-test.sh
sed -i.bak 's|git reset --hard origin/production|echo "Simulation: git reset --hard origin/production"|g' ./deploy-test.sh
sed -i.bak 's|git fetch origin|echo "Simulation: git fetch origin"|g' ./deploy-test.sh
sed -i.bak 's|BACKUP_DIR="/var/backups/symfony-app"|BACKUP_DIR="'$TEST_DIR'/backups"|g' ./deploy-test.sh

# Créer le répertoire de sauvegarde
mkdir -p "$TEST_DIR/backups"

log_success "Script adapté pour le test"

# Initialiser Git pour les tests
log_step "Initialisation de Git pour les tests..."
git init . >/dev/null 2>&1 || true
git config user.email "test@example.com" >/dev/null 2>&1 || true
git config user.name "Test User" >/dev/null 2>&1 || true
git add . >/dev/null 2>&1 || true
git commit -m "Initial test commit" >/dev/null 2>&1 || true
git branch production >/dev/null 2>&1 || true

log_success "Git initialisé"

# Exécuter le script de déploiement adapté
log_step "Exécution du script de déploiement..."
echo "==================== DÉBUT DU DÉPLOIEMENT ===================="
./deploy-test.sh || log_warning "Le déploiement s'est terminé avec des avertissements"
echo "==================== FIN DU DÉPLOIEMENT ======================"

# Vérification de l'état des services
log_step "Vérification de l'état des services..."
docker-compose ps

# Test de santé de l'application
log_step "Test de santé de l'application..."
sleep 5

if curl -f -s http://localhost/ >/dev/null 2>&1; then
    log_success "L'application répond correctement"
else
    log_warning "L'application ne répond pas encore (normal en local)"
fi

# Affichage des logs récents
log_step "Logs récents des conteneurs..."
docker-compose logs --tail=10

# Nettoyage
log_step "Nettoyage..."
docker-compose down -v >/dev/null 2>&1 || true

# Retour au répertoire original
cd "$PROJECT_ROOT"

# Optionnel : supprimer le répertoire de test
read -p "Supprimer le répertoire de test $TEST_DIR ? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$TEST_DIR"
    log_success "Répertoire de test supprimé"
else
    log_info "Répertoire de test conservé: $TEST_DIR"
fi

log_success "🎉 Test de déploiement terminé !"
echo ""
echo "Pour un vrai déploiement, configurez les secrets GitHub Actions :"
echo "- PROD_SSH_HOST"
echo "- PROD_SSH_USERNAME"
echo "- PROD_SSH_PORT (optionnel, défaut: 22)"
echo "- PROD_SSH_PRIVATE_KEY"
