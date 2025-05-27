#!/bin/bash
set -e  # Stop on error

PROJECT_PATH="/monapp/symfony-docker-ci-cd"
CONTAINER="symfony-docker-ci-cd_php_1"
BACKUP_DIR="/var/backups/symfony-app"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Couleurs pour logs
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log() { echo -e "${1}${2}${NC}"; }
info() { log "$BLUE" "INFO: $1"; }
success() { log "$GREEN" "SUCCESS: $1"; }
warn() { log "$YELLOW" "WARNING: $1"; }
error() { log "$RED" "ERROR: $1"; }

check_prereqs() {
  info "Vérification des prérequis..."
  docker ps >/dev/null || { error "Docker non démarré"; exit 1; }
  [ -d "$PROJECT_PATH" ] || { error "Projet introuvable"; exit 1; }
  docker ps -a --format "{{.Names}}" | grep -q "$CONTAINER" || { error "Conteneur absent"; exit 1; }
  success "Pré-requis OK"
}

backup() {
  info "Création sauvegarde..."
  mkdir -p "$BACKUP_DIR"
  tar -czf "$BACKUP_DIR/source_$TIMESTAMP.tar.gz" -C "$PROJECT_PATH" . || warn "Sauvegarde code échouée"
  if docker exec "$CONTAINER" which mysqldump >/dev/null 2>&1; then
    docker exec "$CONTAINER" mysqldump -h mysql -u symfony -psymfony symfony_app > "$BACKUP_DIR/database_$TIMESTAMP.sql" || warn "Sauvegarde BDD échouée"
  fi
  success "Sauvegarde terminée"
}

update_code() {
  info "Mise à jour du code..."
  cd "$PROJECT_PATH"
  docker exec -u www-data "$CONTAINER" git config --global --add safe.directory /var/www
  docker exec -u www-data "$CONTAINER" git fetch origin
  docker exec -u www-data "$CONTAINER" git reset --hard origin/production
  success "Code à jour"
}

cleanup() {
  info "Nettoyage cache et vendor..."
  docker exec -u www-data "$CONTAINER" rm -rf var/cache/* var/log/* vendor composer.lock || true
  success "Nettoyage fait"
}

setup_env() {
  info "Configuration environnement prod..."
  docker exec -u www-data "$CONTAINER" bash -c 'echo -e "APP_ENV=prod\nAPP_DEBUG=0" > .env.local'
  success "Environnement configuré"
}

install_deps() {
  info "Installation dépendances Composer..."
  docker exec -u www-data "$CONTAINER" composer install --no-dev --optimize-autoloader --no-scripts --no-interaction --prefer-dist
  success "Dépendances installées"
}

update_db() {
  info "Mise à jour base de données..."
  docker exec -u www-data "$CONTAINER" bash -c 'APP_ENV=prod php bin/console doctrine:database:create --if-not-exists' || warn "BDD existante ou création échouée"
  docker exec -u www-data "$CONTAINER" bash -c 'APP_ENV=prod php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration' || warn "Migrations échouées"
  success "Base mise à jour"
}

compile_assets() {
  info "Compilation assets..."
  docker exec -u www-data "$CONTAINER" bash -c 'APP_ENV=prod php bin/console asset-map:compile' 2>/dev/null || warn "AssetMapper échoué"
  docker exec -u www-data "$CONTAINER" bash -c 'APP_ENV=prod php bin/console assets:install --symlink --relative' 2>/dev/null || warn "Installation assets échouée"
  success "Assets compilés"
}

manage_cache() {
  info "Gestion cache Symfony..."
  docker exec -u www-data "$CONTAINER" bash -c 'APP_ENV=prod php bin/console cache:clear'
  docker exec -u www-data "$CONTAINER" bash -c 'APP_ENV=prod php bin/console cache:warmup'
  success "Cache rafraîchi"
}

restart_services() {
  info "Redémarrage services..."
  docker-compose -f "$PROJECT_PATH/compose.yaml" restart php nginx
  success "Services redémarrés"
}

health_check() {
  info "Vérification santé app..."
  sleep 10
  if curl -f -s http://izyfreeautomationeu.fr/ >/dev/null 2>&1; then
    success "Application OK"
    return 0
  else
    warn "Application ne répond pas correctement"
    return 1
  fi
}

rollback() {
  error "Déploiement échoué, rollback..."
  LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/source_*.tar.gz 2>/dev/null | head -n 2 | tail -n 1)
  if [ -n "$LATEST_BACKUP" ]; then
    info "Rollback vers $LATEST_BACKUP"
    cd "$PROJECT_PATH"
    tar -xzf "$LATEST_BACKUP" . || error "Rollback échoué"
    restart_services
    info "Rollback terminé"
  else
    error "Aucune sauvegarde disponible"
  fi
}

main() {
  info "Début déploiement"
  trap 'rollback; exit 1' ERR

  check_prereqs
  backup
  update_code
  cleanup
  setup_env
  install_deps
  update_db
  compile_assets
  manage_cache
  restart_services

  health_check && success "Déploiement réussi !" || (warn "Déploiement avec problèmes" && exit 1)
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
