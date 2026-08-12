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

# 3. Configure PHP-FPM to run its worker pool as our non-root user
RUN sed -i \
    -e "s/^user = .*/user = appuser/" \
    -e "s/^group = .*/group = appuser/" \
    /usr/local/etc/php-fpm.d/www.conf

# 4. Copy Composer from the official Composer image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 5. Set the working directory
WORKDIR /var/www/html

# 6. Create a non-root user to run the application
RUN groupadd -g 1000 appuser && \
    useradd -u 1000 -g appuser -m appuser && \
    chown -R appuser:appuser /var/www/html

USER appuser