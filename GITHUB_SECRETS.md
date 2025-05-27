# Configuration des Secrets GitHub Actions

## 🔑 Secrets requis pour le déploiement

Pour que le déploiement automatique fonctionne, vous devez configurer les secrets suivants dans votre repository GitHub :

### 1. PROD_SSH_HOST
- **Description** : Adresse IP ou nom de domaine de votre serveur de production
- **Exemple** : `192.168.1.100` ou `monserveur.example.com`

### 2. PROD_SSH_USERNAME
- **Description** : Nom d'utilisateur SSH pour se connecter au serveur
- **Exemple** : `deploy`, `ubuntu`, `root`

### 3. PROD_SSH_PRIVATE_KEY
- **Description** : Clé privée SSH (format PEM)
- **Génération** :
  ```bash
  # Sur votre machine locale
  ssh-keygen -t rsa -b 4096 -C "github-actions@monprojet.com"
  
  # Copier la clé publique sur le serveur
  ssh-copy-id -i ~/.ssh/id_rsa.pub username@server
  
  # Copier le contenu de la clé privée dans le secret
  cat ~/.ssh/id_rsa
  ```

### 4. PROD_SSH_PORT (optionnel)
- **Description** : Port SSH du serveur (défaut: 22)
- **Exemple** : `22`, `2222`, `443`

## 📋 Étapes de configuration

### 1. Aller dans les paramètres du repository
```
GitHub Repository → Settings → Secrets and variables → Actions
```

### 2. Cliquer sur "New repository secret"

### 3. Ajouter chaque secret individuellement
- Nom : `PROD_SSH_HOST`
- Valeur : `votre-serveur.example.com`

### 4. Répéter pour tous les secrets

## 🛠️ Préparation du serveur de production

### 1. Installer Docker et Docker Compose
```bash
# Sur Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. Cloner le repository
```bash
sudo mkdir -p /var/www
cd /var/www
sudo git clone https://github.com/votre-username/symfony-docker-ci-cd.git
sudo chown -R $USER:$USER /var/www/symfony-docker-ci-cd
```

### 3. Configuration initiale
```bash
cd /var/www/symfony-docker-ci-cd
cp .env.example .env
cp .env.prod.example .env.prod

# Éditer les fichiers d'environnement
nano .env.prod
```

### 4. Premier déploiement
```bash
# Construire et démarrer les services
docker-compose up -d --build

# Installer les dépendances
docker-compose exec php composer install --no-dev --optimize-autoloader

# Configurer la base de données
docker-compose exec php php bin/console doctrine:database:create
docker-compose exec php php bin/console doctrine:migrations:migrate --no-interaction
```

## 🧪 Tester le déploiement

### Test local (sans serveur)
```bash
# Test de la syntaxe du script
make deploy-test

# Test complet avec environnement simulé
make test-deploy
```

### Test sur le serveur
```bash
# Se connecter au serveur
ssh username@votre-serveur.example.com

# Aller dans le répertoire du projet
cd /var/www/symfony-docker-ci-cd

# Tester le script de déploiement
./deploy.sh
```

## 🔧 Débogage

### Problèmes courants

| Erreur                          | Solution                                       |
| ------------------------------- | ---------------------------------------------- |
| `missing server host`           | Vérifier que `PROD_SSH_HOST` est configuré     |
| `Permission denied (publickey)` | Vérifier la clé SSH et les permissions         |
| `Connection refused`            | Vérifier que SSH est activé et le port correct |
| `Docker not found`              | Installer Docker sur le serveur                |
| `Container not found`           | Vérifier que les conteneurs sont démarrés      |

### Logs de débogage
```bash
# Sur le serveur, vérifier les logs
docker-compose logs php
docker-compose logs nginx
docker-compose logs database

# Vérifier l'état des conteneurs
docker-compose ps

# Tester la connectivité
curl -v http://localhost/
```

## ✅ Validation

Une fois configuré, le déploiement se déclenchera automatiquement lors d'un push sur la branche `production` :

```bash
# Créer et pousser vers la branche production
git checkout -b production
git push origin production
```

Le workflow GitHub Actions affichera :
- ✅ `SSH secrets are configured` si tout est correct
- ❌ `SSH secrets are not configured` si des secrets manquent
