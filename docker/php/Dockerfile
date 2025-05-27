# Image de base PHP 8.3 avec FPM sur Alpine Linux (système léger)
FROM php:8.3-fpm-alpine

# Metadata pour l'image
LABEL maintainer="Votre équipe DevOps"
LABEL description="PHP 8.3 FPM pour Symfony avec extensions optimisées"

# Variables d'environnement pour Composer
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_HOME=/tmp

# Installation des outils système nécessaires au développement
# apk = gestionnaire de paquets d'Alpine Linux
# --no-cache = ne garde pas le cache pour réduire la taille de l'image
RUN apk --no-cache add \
    curl \
    git \
    wget \
    bash \
    dpkg \
    unzip \
    && rm -rf /var/cache/apk/*

# Téléchargement de l'installateur d'extensions PHP (outil tiers très pratique)
# Cet outil simplifie l'installation des extensions PHP dans Docker
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Donner les permissions d'exécution à l'installateur d'extensions
# chmod +x = rendre le fichier exécutable
RUN chmod +x /usr/local/bin/install-php-extensions

# Installation des extensions PHP pour l'optimisation et les conversions
# opcache = accélère PHP en mettant le code en cache
# iconv = conversion d'encodage de caractères
# soap = protocole de communication web (services web)
RUN install-php-extensions opcache iconv soap

# Installation des extensions PHP pour la manipulation de fichiers
# zip = compression/décompression de fichiers ZIP
# intl = internationalisation (dates, nombres selon pays)
# fileinfo = obtenir des informations sur les fichiers
RUN install-php-extensions zip intl fileinfo

# Installation des extensions PHP pour les bases de données
# pdo = interface uniforme pour accéder aux bases de données
# redis = base de données en mémoire (cache rapide)
# mysqli = interface MySQL améliorée
# pdo_mysql = driver PDO spécifique à MySQL
RUN install-php-extensions pdo redis mysqli pdo_mysql

# Installation de l'extension PHP pour les images
# gd = bibliothèque pour créer et manipuler des images (redimensionner, etc.)
RUN install-php-extensions gd

# Installation de Composer (gestionnaire de dépendances PHP)
# Version fixe pour la reproductibilité
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Définir le répertoire de travail dans le conteneur
# Tous les fichiers de votre application Symfony seront ici
# /var/www = répertoire standard pour les applications web
WORKDIR /var/www

# Créer les répertoires nécessaires avec les bonnes permissions
RUN mkdir -p var/cache var/log var/sessions \
    && chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www

# Changer le propriétaire des fichiers vers www-data (utilisateur dans le conteneur)
RUN chown -R www-data:www-data /var/www

# Exposer le port PHP-FPM
EXPOSE 9000

# Health check pour vérifier que PHP-FPM fonctionne
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD pgrep php-fpm > /dev/null || exit 1

# Travailler avec l'utilisateur www-data
USER www-data