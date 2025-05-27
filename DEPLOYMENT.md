# Guide de Déploiement

Ce document explique comment utiliser le script de déploiement `deploy.sh` pour Symfony Docker CI/CD.

## 🎯 Objectif

Le script `deploy.sh` automatise le déploiement en production en :
- ✅ Vérifiant les prérequis
- 💾 Créant des sauvegardes automatiques
- 🔄 Mettant à jour le code depuis la branche `production`
- 🧹 Nettoyant et optimisant l'environnement
- 🗄️ Migrant la base de données
- 🎨 Compilant les assets
- 🔄 Redémarrant les services
- 🏥 Effectuant des vérifications de santé
- ↩️ Gérant les rollbacks automatiques en cas d'erreur

## 📋 Prérequis

### Sur le serveur de production

1. **Docker et Docker Compose** installés et fonctionnels
2. **Projet déployé** dans `/var/www/symfony-docker-ci-cd`
3. **Conteneurs** nommés selon la convention :
   - PHP : `symfony-docker-ci-cd_php_1`
   - MySQL : `symfony-docker-ci-cd_mysql_1`
4. **Permissions** : l'utilisateur doit pouvoir exécuter Docker
5. **Git configuré** avec accès au repository

### Structure attendue

```
/var/www/symfony-docker-ci-cd/
├── deploy.sh                 # Script de déploiement
├── compose.yaml              # Configuration Docker Compose
├── .env                      # Variables d'environnement
├── .env.prod                 # Variables de production
└── ...                       # Reste du projet Symfony
```

## 🚀 Utilisation

### Déploiement automatique via GitHub Actions

Le déploiement se déclenche automatiquement :
```yaml
# Push sur la branche production
git push origin production

# Ou après succès du CI sur production
```

### Déploiement manuel sur le serveur

```bash
# Se connecter au serveur de production
ssh user@production-server

# Aller dans le répertoire du projet
cd /var/www/symfony-docker-ci-cd

# Exécuter le déploiement
./deploy.sh
```

### Test local du script

```bash
# Vérifier la syntaxe du script
make deploy-test

# Ou directement
bash -n deploy.sh
```

## 📊 Fonctionnalités du script

### 1. Vérification des prérequis ✅
- Docker en cours d'exécution
- Existence du répertoire projet
- Existence des conteneurs

### 2. Sauvegarde automatique 💾
```bash
# Sauvegarde dans /var/backups/symfony-app/
source_YYYYMMDD_HHMMSS.tar.gz  # Code source
database_YYYYMMDD_HHMMSS.sql   # Base de données
```

### 3. Mise à jour sécurisée 🔄
- Récupération depuis `origin/production`
- Reset hard pour éviter les conflits
- Configuration Git safe.directory

### 4. Optimisation production ⚡
```bash
composer install --no-dev --optimize-autoloader --no-scripts
APP_ENV=prod php bin/console cache:clear
APP_ENV=prod php bin/console cache:warmup
```

### 5. Gestion d'erreurs ↩️
- Rollback automatique en cas d'échec
- Logs colorés pour un suivi facile
- Vérifications de santé

## 🔧 Configuration

### Variables du script (modifiables)

```bash
PROJECT_PATH="/var/www/symfony-docker-ci-cd"    # Chemin du projet
CONTAINER_NAME="symfony-docker-ci-cd_php_1"    # Nom du conteneur PHP
BACKUP_DIR="/var/backups/symfony-app"          # Répertoire de sauvegarde
```

### Secrets GitHub Actions requis

```yaml
PROD_SSH_HOST         # IP ou nom de domaine du serveur
PROD_SSH_USERNAME     # Utilisateur SSH
PROD_SSH_PORT         # Port SSH (généralement 22)
PROD_SSH_PRIVATE_KEY  # Clé privée SSH
```

## 🔍 Monitoring et logs

### Logs du script
Le script affiche des logs colorés en temps réel :
- 🔵 **Info** : Informations générales
- 🟢 **Succès** : Opérations réussies
- 🟡 **Avertissement** : Problèmes mineurs
- 🔴 **Erreur** : Problèmes critiques

### Vérification de santé
```bash
# Le script vérifie automatiquement
curl -f http://localhost/

# Vérification manuelle
docker ps                    # Conteneurs en cours
docker logs container_name   # Logs spécifiques
```

## 🚨 Gestion des erreurs

### Échec de déploiement
```bash
# Le script tente automatiquement un rollback
# Sinon, rollback manuel :
cd /var/www/symfony-docker-ci-cd
tar -xzf /var/backups/symfony-app/source_LATEST.tar.gz
docker-compose restart
```

### Problèmes courants

| Problème         | Solution                                             |
| ---------------- | ---------------------------------------------------- |
| Conteneur absent | `docker-compose up -d`                               |
| Permissions Git  | `git config --global --add safe.directory /var/www`  |
| Cache corrompu   | `rm -rf var/cache/* && php bin/console cache:warmup` |
| Base de données  | Vérifier les credentials dans `.env.prod`            |

## 📈 Optimisations futures

- [ ] Support multi-serveur (load balancer)
- [ ] Déploiement Blue/Green
- [ ] Tests automatiques post-déploiement
- [ ] Notifications Slack/Discord
- [ ] Métriques de performance

## 🔗 Ressources

- [Documentation Symfony Deployment](https://symfony.com/doc/current/deployment.html)
- [Docker Compose Production](https://docs.docker.com/compose/production/)
- [GitHub Actions SSH](https://github.com/marketplace/actions/ssh-remote-commands)
