#!/bin/bash

# Script de déploiement en production pour Symfony avec Docker
# Ce script s'exécute sur le serveur de production

set -e  # Arrêter le script si une commande échoue

# --- Configuration des variables ---

# Chemin local du projet sur le serveur
PROJECT_PATH="/monapp/symfony-docker-ci-cd"

# Nom du conteneur Docker PHP où s'exécute l'application
CONTAINER_NAME="symfony-docker-ci-cd_php_1"

# Répertoire où les sauvegardes seront stockées
BACKUP_DIR="/var/backups/symfony-app"

# Horodatage pour nommer les sauvegardes (année mois jour_heure minute seconde)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# --- Couleurs pour afficher les logs dans le terminal ---
RED='\033[0;31m'      # Rouge (erreur)
GREEN='\033[0;32m'    # Vert (succès)
YELLOW='\033[1;33m'   # Jaune (avertissement)
BLUE='\033[0;34m'     # Bleu (info)
NC='\033[0m'          # Reset couleur

# --- Fonctions pour afficher les messages avec couleur ---

log_info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

log_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

log_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

log_step() {
    echo -e "${BLUE}STEP: $1${NC}"
}

# --- Vérification des prérequis avant déploiement ---

check_prerequisites() {
    log_step "Vérification des prérequis..."

    # Vérifie que Docker tourne bien sur le serveur
    if ! docker ps >/dev/null 2>&1; then
        log_error "Docker n'est pas en cours d'exécution"
        exit 1
    fi
    log_success "Docker est en cours d'exécution"

    # Vérifie que le dossier du projet existe sur le serveur
    if [ ! -d "$PROJECT_PATH" ]; then
        log_error "Le dossier projet $PROJECT_PATH n'existe pas"
        exit 1
    fi
    log_success "Le dossier projet existe"

    # Vérifie que le conteneur Docker PHP est présent
    if ! docker ps -a --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
        log_error "Le conteneur $CONTAINER_NAME n'existe pas"
        exit 1
    fi
    log_success "Le conteneur existe"
}

# --- Création d'une sauvegarde avant mise à jour ---

create_backup() {
    log_step "Création de la sauvegarde..."

    # Crée le dossier de sauvegarde s'il n'existe pas
    mkdir -p "$BACKUP_DIR"

    # Sauvegarde le code source en compressant tout le dossier du projet
    if [ -d "$PROJECT_PATH" ]; then
        tar -czf "$BACKUP_DIR/source_$TIMESTAMP.tar.gz" -C "$PROJECT_PATH" . 2>/dev/null || log_warning "Impossible de sauvegarder le code source"
        log_success "Code source sauvegardé dans $BACKUP_DIR/source_$TIMESTAMP.tar.gz"
    fi

    # Sauvegarde la base de données MySQL si mysqldump est disponible dans le conteneur
    if docker exec "$CONTAINER_NAME" which mysqldump >/dev/null 2>&1; then
        docker exec "$CONTAINER_NAME" mysqldump -h mysql -u symfony -psymfony symfony_app > "$BACKUP_DIR/database_$TIMESTAMP.sql" 2>/dev/null || log_warning "Impossible de sauvegarder la base de données"
        log_success "Base de données sauvegardée dans $BACKUP_DIR/database_$TIMESTAMP.sql"
    fi
}

# --- Mise à jour du code source via Git dans le conteneur ---

update_code() {
    log_step "Mise à jour du code source..."

    # Se placer dans le dossier du projet sur le serveur (hôte)
    cd "$PROJECT_PATH" || exit 1

    # Autoriser Git à gérer ce répertoire (important dans certains conteneurs)
    docker exec -u www-data "$CONTAINER_NAME" git config --global --add safe.directory /var/www

    # Récupérer les dernières modifications depuis la branche 'production'
    docker exec -u www-data "$CONTAINER_NAME" git fetch origin
    docker exec -u www-data "$CONTAINER_NAME" git reset --hard origin/production

    log_success "Code source mis à jour depuis la branche production"
}

# --- Nettoyage des fichiers temporaires dans le conteneur ---

cleanup() {
    log_step "Nettoyage des caches et dépendances..."

    # Supprimer les caches et logs dans le conteneur
    docker exec -u www-data "$CONTAINER_NAME" rm -rf var/cache/* var/log/* || true

    # Supprimer le dossier vendor et le fichier composer.lock pour réinstaller proprement
    docker exec -u www-data "$CONTAINER_NAME" rm -rf vendor composer.lock || true

    log_success "Nettoyage effectué"
}

# --- Configuration de l'environnement Symfony en production ---

setup_environment() {
    log_step "Configuration de l'environnement de production..."

    # Créer ou écraser le fichier .env.local avec les variables d'environnement pour la production
    docker exec -u www-data "$CONTAINER_NAME" bash -c 'cat > .env.local << EOF
APP_ENV=prod
APP_DEBUG=0
EOF'

    log_success "Environnement de production configuré"
}

# --- Installation des dépendances PHP en production ---

install_dependencies() {
    log_step "Installation des dépendances en production..."

    # Installer Composer sans les dépendances de développement, de façon optimisée
    docker exec -u www-data "$CONTAINER_NAME" composer install \
        --no-dev \
        --optimize-autoloader \
        --no-scripts \
        --no-interaction \
        --prefer-dist

    log_success "Dépendances installées"
}

# --- Mise à jour de la base de données avec Doctrine ---

update_database() {
    log_step "Mise à jour de la base de données..."

    # Créer la base si elle n'existe pas déjà (ignore l'erreur si déjà créée)
    docker exec -u www-data "$CONTAINER_NAME" bash -c 'APP_ENV=prod php bin/console doctrine:database:create --if-not-exists' || log_warning "Création base de données échouée ou déjà existante"

    # Exécuter les migrations de la base de données (ignore si aucune migration)
    docker exec -u www-data "$CONTAINER_NAME" bash -c 'APP_ENV=prod php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration' || log_warning "Migration de la base échouée"

    log_success "Base de données mise à jour"
}

# --- Compilation des assets pour la production ---

compile_assets() {
    log_step "Compilation des assets..."

    # Compiler les assets avec AssetMapper (Symfony 6.3+), ignorer si échec
    docker exec -u www-data "$CONTAINER_NAME" bash -c 'APP_ENV=prod php bin/console asset-map:compile' 2>/dev/null || log_warning "Compilation AssetMapper échouée"

    # Installer les assets publics (liens symboliques relatifs), ignorer si échec
    docker exec -u www-data "$CONTAINER_NAME" bash -c 'APP_ENV=prod php bin/console assets:install --symlink --relative' 2>/dev/null || log_warning "Installation des assets échouée"

    log_success "Assets compilés"
}

# --- Gestion du cache Symfony ---

manage_cache() {
    log_step "Gestion du cache..."

    # Vider le cache de l'application
    docker exec -u www-data "$CONTAINER_NAME" bash -c 'APP_ENV=prod php bin/console cache:clear'

    # Préchauffer le cache pour accélérer les futures requêtes
    docker exec -u www-data "$CONTAINER_NAME" bash -c 'APP_ENV=prod php bin/console cache:warmup'

    log_success "Cache vidé et préchauffé"
}

# --- Redémarrage des services PHP et Nginx via docker-compose ---

restart_services() {
    log_step "Redémarrage des services..."

    # Redémarrer les conteneurs PHP et Nginx définis dans le fichier compose.yaml
    docker-compose -f "$PROJECT_PATH/compose.yaml" restart php nginx

    log_success "Services redémarrés"
}

# --- Vérification de la santé de l'application via HTTP ---

health_check() {
    log_step "Vérification de l'état de l'application..."

    # Attendre 10 secondes pour laisser le temps aux services de redémarrer
    sleep 10

    # Tester l'accès HTTP au site (changer l'URL si nécessaire)
    if curl -f -s http://izyfreeautomationeu.fr/ >/dev/null 2>&1; then
        log_success "L'application répond correctement"
        return 0
    else
        log_warning "L'application ne répond peut-être pas correctement"
        return 1
    fi
}

# --- En cas d'erreur, tenter un rollback avec la dernière sauvegarde ---

rollback() {
    log_error "Le déploiement a échoué ! Tentative de rollback..."

    # Trouver la sauvegarde la plus récente avant la dernière (pour éviter la sauvegarde en cours)
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/source_*.tar.gz 2>/dev/null | head -n 2 | tail -n 1)

    if [ -n "$LATEST_BACKUP" ]; then
        log_step "Rollback vers la sauvegarde $LATEST_BACKUP"
        cd "$PROJECT_PATH" || exit 1
        tar -xzf "$LATEST_BACKUP" . 2>/dev/null || log_error "Échec du rollback"
        restart_services
        log_info "Rollback terminé"
    else
        log_error "Aucune sauvegarde disponible pour rollback"
    fi
}

# --- Fonction principale qui lance toutes les étapes du déploiement ---

main() {
    log_info "Début du déploiement en production..."

    # Si une commande échoue, exécuter rollback puis quitter
    trap 'rollback; exit 1' ERR

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

    # Vérification finale du bon fonctionnement de l'application
    if health_check; then
        log_success "Déploiement terminé avec succès !"
        exit 0
    else
        log_warning "Déploiement terminé mais la vérification de santé a échoué"
        exit 1
    fi
}

# --- Point d'entrée du script ---

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
