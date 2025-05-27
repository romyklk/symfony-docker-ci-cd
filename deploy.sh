#!/bin/bash

# Script de déploiement en production pour Symfony Docker CI/CD
# Ce script doit être exécuté sur le serveur de production

set -e  # Arrêter le script si une commande échoue

# Configuration
PROJECT_PATH="/var/www/symfony-docker-ci-cd"
CONTAINER_NAME="symfony-docker-ci-cd_php_1"
BACKUP_DIR="/var/backups/symfony-app"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages avec couleur
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

# Fonction de vérification des prérequis
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Vérifier que Docker est en cours d'exécution
    if ! docker ps >/dev/null 2>&1; then
        log_error "Docker is not running"
        exit 1
    fi
    log_success "Docker is running"
    
    # Vérifier que le répertoire du projet existe
    if [ ! -d "$PROJECT_PATH" ]; then
        log_error "Project directory $PROJECT_PATH does not exist"
        exit 1
    fi
    log_success "Project directory exists"
    
    # Vérifier que le conteneur existe
    if ! docker ps -a --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
        log_error "Container $CONTAINER_NAME does not exist"
        exit 1
    fi
    log_success "Container exists"
}

# Fonction de sauvegarde
create_backup() {
    log_step "Creating backup..."
    
    # Créer le répertoire de sauvegarde s'il n'existe pas
    mkdir -p "$BACKUP_DIR"
    
    # Sauvegarder le code source
    if [ -d "$PROJECT_PATH" ]; then
        tar -czf "$BACKUP_DIR/source_$TIMESTAMP.tar.gz" -C "$PROJECT_PATH" . 2>/dev/null || log_warning "Could not backup source code"
        log_success "Source code backed up to $BACKUP_DIR/source_$TIMESTAMP.tar.gz"
    fi
    
    # Sauvegarder la base de données
    if docker exec "$CONTAINER_NAME" which mysqldump >/dev/null 2>&1; then
        docker exec "$CONTAINER_NAME" mysqldump -h mysql -u symfony -psymfony symfony_app > "$BACKUP_DIR/database_$TIMESTAMP.sql" 2>/dev/null || log_warning "Could not backup database"
        log_success "Database backed up to $BACKUP_DIR/database_$TIMESTAMP.sql"
    fi
}

# Fonction de mise à jour du code
update_code() {
    log_step "Updating code..."
    
    cd "$PROJECT_PATH" || exit 1
    
    # Autoriser le répertoire Git
    docker exec -u www-data "$CONTAINER_NAME" git config --global --add safe.directory /var/www
    
    # Récupérer les dernières modifications
    docker exec -u www-data "$CONTAINER_NAME" git fetch origin
    docker exec -u www-data "$CONTAINER_NAME" git reset --hard origin/production
    
    log_success "Code updated from production branch"
}

# Fonction de nettoyage
cleanup() {
    log_step "Cleaning up..."
    
    # Supprimer les fichiers de cache et logs
    docker exec -u www-data "$CONTAINER_NAME" rm -rf var/cache/* var/log/* || true
    
    # Supprimer vendor et composer.lock pour une installation propre
    docker exec -u www-data "$CONTAINER_NAME" rm -rf vendor composer.lock || true
    
    log_success "Cleanup completed"
}

# Fonction de configuration de l'environnement
setup_environment() {
    log_step "Setting up production environment..."
    
    # Créer le fichier .env.local pour forcer l'environnement de production
    docker exec -u www-data "$CONTAINER_NAME" bash -c 'cat > .env.local << EOF
APP_ENV=prod
APP_DEBUG=0
EOF'
    
    log_success "Production environment configured"
}

# Fonction d'installation des dépendances
install_dependencies() {
    log_step "Installing production dependencies..."
    
    # Installation optimisée pour la production
    docker exec -u www-data "$CONTAINER_NAME" composer install \
        --no-dev \
        --optimize-autoloader \
        --no-scripts \
        --no-interaction \
        --prefer-dist
    
    log_success "Dependencies installed"
}

# Fonction de gestion de la base de données
update_database() {
    log_step "Updating database..."
    
    # Créer la base de données si elle n'existe pas
    docker exec -u www-data "$CONTAINER_NAME" bash -c 'APP_ENV=prod php bin/console doctrine:database:create --if-not-exists' || log_warning "Database creation failed or already exists"
    
    # Exécuter les migrations
    docker exec -u www-data "$CONTAINER_NAME" bash -c 'APP_ENV=prod php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration' || log_warning "Migration failed"
    
    log_success "Database updated"
}

# Fonction de compilation des assets
compile_assets() {
    log_step "Compiling assets..."
    
    # Compiler les assets avec AssetMapper (Symfony 6.3+)
    docker exec -u www-data "$CONTAINER_NAME" bash -c 'APP_ENV=prod php bin/console asset-map:compile' 2>/dev/null || log_warning "AssetMapper compilation failed"
    
    # Installer les assets publics
    docker exec -u www-data "$CONTAINER_NAME" bash -c 'APP_ENV=prod php bin/console assets:install --symlink --relative' 2>/dev/null || log_warning "Assets installation failed"
    
    log_success "Assets compiled"
}

# Fonction de gestion du cache
manage_cache() {
    log_step "Managing cache..."
    
    # Vider le cache
    docker exec -u www-data "$CONTAINER_NAME" bash -c 'APP_ENV=prod php bin/console cache:clear'
    
    # Préchauffer le cache
    docker exec -u www-data "$CONTAINER_NAME" bash -c 'APP_ENV=prod php bin/console cache:warmup'
    
    log_success "Cache cleared and warmed up"
}

# Fonction de redémarrage des services
restart_services() {
    log_step "Restarting services..."
    
    # Redémarrer les conteneurs PHP et Nginx
    docker-compose -f "$PROJECT_PATH/compose.yaml" restart php nginx
    
    log_success "Services restarted"
}

# Fonction de vérification de santé
health_check() {
    log_step "Performing health check..."
    
    # Attendre que les services redémarrent
    sleep 10
    
    # Vérifier que l'application répond
    if curl -f -s http://izyfreeautomationeu.fr/ >/dev/null 2>&1; then
        log_success "Application is responding correctly"
        return 0
    else
        log_warning "Application may not be responding correctly"
        return 1
    fi
}

# Fonction de rollback
rollback() {
    log_error "Deployment failed! Attempting rollback..."
    
    # Chercher la dernière sauvegarde
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/source_*.tar.gz 2>/dev/null | head -n 2 | tail -n 1)
    
    if [ -n "$LATEST_BACKUP" ]; then
        log_step "Rolling back to $LATEST_BACKUP"
        cd "$PROJECT_PATH"
        tar -xzf "$LATEST_BACKUP" . 2>/dev/null || log_error "Rollback failed"
        restart_services
        log_info "Rollback completed"
    else
        log_error "No backup found for rollback"
    fi
}

# Fonction principale
main() {
    log_info "🚀 Starting production deployment..."
    
    # Trap pour gérer les erreurs
    trap 'rollback; exit 1' ERR
    
    # Exécuter les étapes de déploiement
    check_prerequisites
    create_backup
    update_code
    cleanup
    setup_environment
    install_dependencies
    update_database
    compile_assets
    manage_cache
    restart_services
    
    # Vérification finale
    if health_check; then
        log_success "🎉 Production deployment completed successfully!"
        exit 0
    else
        log_warning "⚠️ Deployment completed but health check failed"
        exit 1
    fi
}

# Point d'entrée du script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
