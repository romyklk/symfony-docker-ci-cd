# Symfony Docker CI/CD

[![CI Pipeline](https://github.com/votre-username/symfony-docker-ci-cd/workflows/CI%20-%20Audit,%20Quality%20&%20Tests/badge.svg)](https://github.com/votre-username/symfony-docker-ci-cd/actions)
[![Deploy Pipeline](https://github.com/votre-username/symfony-docker-ci-cd/workflows/CD%20-%20Deploy%20to%20Production/badge.svg)](https://github.com/votre-username/symfony-docker-ci-cd/actions)

Un projet Symfony 7.2 avec Docker et CI/CD complet utilisant GitHub Actions.

## 🚀 Fonctionnalités

- **Symfony 7.2** avec PHP 8.3
- **Docker & Docker Compose** pour l'environnement de développement
- **CI/CD Pipeline** avec GitHub Actions
- **Qualité de code** avec PHPStan, ECS, Rector
- **Tests automatisés** avec PHPUnit
- **Audit de sécurité** avec Composer
- **Déploiement automatique** en production

## 📋 Prérequis

- Docker & Docker Compose
- Git
- PHP 8.3+ (pour le développement local sans Docker)
- Composer (pour le développement local sans Docker)

## 🛠️ Installation

### Configuration rapide avec Docker

```bash
# Cloner le projet
git clone https://github.com/votre-username/symfony-docker-ci-cd.git
cd symfony-docker-ci-cd

# Configuration automatique de l'environnement
./setup-dev.sh
```

### Configuration manuelle

```bash
# 1. Copier le fichier d'environnement
cp .env.example .env.local

# 2. Modifier les variables selon vos besoins
nano .env.local

# 3. Construire et démarrer les conteneurs
docker compose build
docker compose up -d

# 4. Installer les dépendances
docker compose exec php composer install

# 5. Configurer la base de données
docker compose exec php php bin/console doctrine:database:create
docker compose exec php php bin/console doctrine:migrations:migrate

# 6. Compiler les assets
docker compose exec php php bin/console asset-map:compile
```

## 🌐 Accès

- **Application** : http://localhost
- **PHPMyAdmin** : http://localhost:8080

## 🔧 Commandes utiles

```bash
# Démarrer les services
docker compose up -d

# Arrêter les services
docker compose down

# Voir les logs
docker compose logs -f

# Console Symfony
docker compose exec php php bin/console

# Tests
docker compose exec php composer app:tests

# Qualité de code
docker compose exec php composer app:code-quality

# Accéder au conteneur PHP
docker compose exec php bash
```

## 📁 Structure du projet

```
├── .github/workflows/     # Pipelines CI/CD
├── assets/               # Assets frontend (JS, CSS)
├── config/               # Configuration Symfony
├── docker/               # Configuration Docker
├── migrations/           # Migrations de base de données
├── public/               # Point d'entrée web
├── src/                  # Code source PHP
├── templates/            # Templates Twig
├── tests/                # Tests PHPUnit
└── var/                  # Cache et logs
```

## 🔄 CI/CD Pipeline

### Pipeline CI (Audit, Qualité, Tests)

Déclenché sur :
- Push sur `main`, `develop`, `feature/*`
- Pull requests vers `main`, `develop`

Étapes :
1. **Audit de sécurité** - Vérification des vulnérabilités
2. **Qualité de code** - PHPStan, ECS, Rector, Lint
3. **Tests** - PHPUnit avec couverture

### Pipeline CD (Déploiement)

Déclenché sur :
- Push sur `production`
- Succès du pipeline CI

Étapes :
1. Sauvegarde de l'état actuel
2. Mise à jour du code
3. Installation des dépendances de production
4. Migration de la base de données
5. Compilation des assets
6. Nettoyage du cache
7. Redémarrage des services
8. Vérification de santé

## 🏗️ Environnements

### Développement
- Fichier : `.env.local`
- Mode debug activé
- Tous les bundles de développement

### Test
- Fichier : `.env.test`
- Base de données séparée
- Pas de cache persistant

### Production
- Fichier : `.env.prod` ou variables d'environnement
- Mode debug désactivé
- Optimisations activées
- Secrets via variables d'environnement

## 🛡️ Sécurité

- Variables sensibles via secrets GitHub
- Connexion SSH sécurisée pour le déploiement
- Audit de sécurité automatique
- Séparation des environnements

## 📊 Qualité de code

Le projet utilise plusieurs outils pour maintenir la qualité :

- **PHPStan** : Analyse statique du code
- **ECS** : Style de code uniforme
- **Rector** : Modernisation automatique du code
- **PHPUnit** : Tests unitaires et fonctionnels

```bash
# Lancer tous les contrôles de qualité
docker compose exec php composer app:code-quality
```

## 🚀 Déploiement

### Automatique
Le déploiement se fait automatiquement lors du push sur la branche `production`.

### Manuel
```bash
# Se connecter au serveur
ssh user@your-server

# Aller dans le répertoire du projet
cd /var/www/symfony-docker-ci-cd

# Lancer le déploiement
git pull origin production
docker compose exec php composer install --no-dev --optimize-autoloader
# ... autres commandes de déploiement
```

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/amazing-feature`)
3. Commit les changements (`git commit -m 'Add amazing feature'`)
4. Push vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrir une Pull Request

## 📝 License

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🆘 Support

Si vous rencontrez des problèmes :

1. Vérifiez les [Issues](https://github.com/votre-username/symfony-docker-ci-cd/issues)
2. Consultez les logs : `docker compose logs -f`
3. Créez une nouvelle issue avec les détails du problème

## 🔗 Liens utiles

- [Documentation Symfony](https://symfony.com/doc)
- [Documentation Docker](https://docs.docker.com)
- [GitHub Actions](https://docs.github.com/en/actions)
