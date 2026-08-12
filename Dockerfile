# Docker  — recipe to build a container image

# Start from a base image with PHP 8.3 and FPM
FROM php:8.3-fpm 

# 1. Install system dependencies required for PHP extensions
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libonig-dev \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 2. Install the required PHP extensions
RUN docker-php-ext-install \
    pdo_mysql \
    intl \
    mbstring

# 3. Copy Composer from the official Composer image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 4. Set the working directory
WORKDIR /var/www/html