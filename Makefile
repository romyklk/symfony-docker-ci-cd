# Makefile pour Symfony Docker CI/CD
# Simplifie les commandes Docker Compose courantes

.PHONY: help build up down restart logs shell test quality audit clean install migrate assets

# Couleurs pour les messages
GREEN=\033[0;32m
YELLOW=\033[1;33m
RED=\033[0;31m
NC=\033[0m # No Color

# Variables
DOCKER_COMPOSE = docker compose
PHP_CONTAINER = php
DATABASE_CONTAINER = database

## Affiche cette aide
help:
	@echo "$(GREEN)Commandes disponibles pour Symfony Docker CI/CD:$(NC)"
	@echo ""
	@echo "$(YELLOW)🐳 Docker:$(NC)"
	@echo "  build         Construire les conteneurs"
	@echo "  up            Démarrer les services"
	@echo "  down          Arrêter les services"
	@echo "  restart       Redémarrer les services"
	@echo "  logs          Afficher les logs"
	@echo ""
	@echo "$(YELLOW)🔧 Développement:$(NC)"
	@echo "  setup         Configuration complète de l'environnement"
	@echo "  shell         Accéder au conteneur PHP"
	@echo "  install       Installer les dépendances"
	@echo "  migrate       Migrer la base de données"
	@echo "  assets        Compiler les assets"
	@echo "  cache-clear   Vider le cache"
	@echo ""
	@echo "$(YELLOW)🧪 Qualité:$(NC)"
	@echo "  test          Lancer les tests"
	@echo "  quality       Vérifier la qualité du code"
	@echo "  audit         Audit de sécurité"
	@echo "  fix           Corriger le style de code"
	@echo ""
	@echo "$(YELLOW)🧹 Maintenance:$(NC)"
	@echo "  clean         Nettoyer Docker"
	@echo "  reset         Reset complet"
	@echo ""
	@echo "$(YELLOW)🚀 Déploiement:$(NC)"
	@echo "  deploy        Lancer le script de déploiement"
	@echo "  deploy-test   Tester le déploiement localement"
	@echo "  test-deploy   Test complet avec environnement simulé"

## 🐳 DOCKER

## Construire les conteneurs
build:
	@echo "$(GREEN)🏗️ Construction des conteneurs...$(NC)"
	$(DOCKER_COMPOSE) build --no-cache

## Démarrer les services
up:
	@echo "$(GREEN)🚀 Démarrage des services...$(NC)"
	$(DOCKER_COMPOSE) up -d

## Arrêter les services
down:
	@echo "$(YELLOW)🛑 Arrêt des services...$(NC)"
	$(DOCKER_COMPOSE) down

## Redémarrer les services
restart: down up

## Afficher les logs
logs:
	$(DOCKER_COMPOSE) logs -f

## 🔧 DÉVELOPPEMENT

## Configuration complète de l'environnement
setup: build up install migrate assets cache-clear
	@echo "$(GREEN)✅ Environnement configuré avec succès!$(NC)"
	@echo "$(GREEN)🌐 Application disponible sur: http://localhost$(NC)"
	@echo "$(GREEN)🗄️ PHPMyAdmin disponible sur: http://localhost:8080$(NC)"

## Accéder au conteneur PHP
shell:
	$(DOCKER_COMPOSE) exec $(PHP_CONTAINER) bash

## Installer les dépendances
install:
	@echo "$(GREEN)📦 Installation des dépendances...$(NC)"
	$(DOCKER_COMPOSE) exec $(PHP_CONTAINER) composer install

## Migrer la base de données
migrate:
	@echo "$(GREEN)🗄️ Migration de la base de données...$(NC)"
	$(DOCKER_COMPOSE) exec $(PHP_CONTAINER) php bin/console doctrine:database:create --if-not-exists
	$(DOCKER_COMPOSE) exec $(PHP_CONTAINER) php bin/console doctrine:migrations:migrate --no-interaction

## Compiler les assets
assets:
	@echo "$(GREEN)🎨 Compilation des assets...$(NC)"
	$(DOCKER_COMPOSE) exec $(PHP_CONTAINER) php bin/console asset-map:compile
	$(DOCKER_COMPOSE) exec $(PHP_CONTAINER) php bin/console assets:install

## Vider le cache
cache-clear:
	@echo "$(GREEN)🧹 Nettoyage du cache...$(NC)"
	$(DOCKER_COMPOSE) exec $(PHP_CONTAINER) php bin/console cache:clear

## 🧪 QUALITÉ

## Lancer les tests
test:
	@echo "$(GREEN)🧪 Lancement des tests...$(NC)"
	$(DOCKER_COMPOSE) exec $(PHP_CONTAINER) composer app:tests

## Vérifier la qualité du code
quality:
	@echo "$(GREEN)🔍 Vérification de la qualité du code...$(NC)"
	$(DOCKER_COMPOSE) exec $(PHP_CONTAINER) composer app:code-quality

## Audit de sécurité
audit:
	@echo "$(GREEN)🛡️ Audit de sécurité...$(NC)"
	$(DOCKER_COMPOSE) exec $(PHP_CONTAINER) composer audit

## Corriger le style de code
fix:
	@echo "$(GREEN)🔧 Correction du style de code...$(NC)"
	$(DOCKER_COMPOSE) exec $(PHP_CONTAINER) vendor/bin/ecs --fix

## 🧹 MAINTENANCE

## Nettoyer Docker
clean:
	@echo "$(YELLOW)🧹 Nettoyage de Docker...$(NC)"
	docker system prune -f
	docker volume prune -f

## Reset complet
reset: down clean
	@echo "$(RED)🔄 Reset complet...$(NC)"
	docker compose down -v
	docker system prune -af
	@echo "$(GREEN)✅ Reset terminé. Lancez 'make setup' pour reconfigurer.$(NC)"

## Commandes rapides
db-shell:
	$(DOCKER_COMPOSE) exec $(DATABASE_CONTAINER) mysql -u root -p

console:
	$(DOCKER_COMPOSE) exec $(PHP_CONTAINER) php bin/console

composer:
	$(DOCKER_COMPOSE) exec $(PHP_CONTAINER) composer $(filter-out $@,$(MAKECMDGOALS))

# Empêcher make de traiter les arguments comme des cibles
%:
	@:

## 🚀 DÉPLOIEMENT

## Lancer le script de déploiement
deploy:
	@echo "$(GREEN)🚀 Lancement du déploiement en production...$(NC)"
	@if [ -f "./deploy.sh" ]; then \
		chmod +x ./deploy.sh && ./deploy.sh; \
	else \
		echo "$(RED)❌ Script deploy.sh non trouvé$(NC)"; \
		exit 1; \
	fi

## Tester le déploiement localement (simulation)
deploy-test:
	@echo "$(GREEN)🧪 Test du script de déploiement...$(NC)"
	@echo "$(YELLOW)⚠️  Mode test - aucune modification réelle$(NC)"
	@if [ -f "./deploy.sh" ]; then \
		chmod +x ./deploy.sh && bash -n ./deploy.sh && echo "$(GREEN)✅ Script valide$(NC)"; \
	else \
		echo "$(RED)❌ Script deploy.sh non trouvé$(NC)"; \
		exit 1; \
	fi

## Test complet avec environnement simulé
test-deploy:
	@echo "$(GREEN)🧪 Test complet du déploiement...$(NC)"
	@if [ -f "./test-deploy.sh" ]; then \
		chmod +x ./test-deploy.sh && ./test-deploy.sh; \
	else \
		echo "$(RED)❌ Script test-deploy.sh non trouvé$(NC)"; \
		exit 1; \
	fi
