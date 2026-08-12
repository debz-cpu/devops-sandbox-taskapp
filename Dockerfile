# ---------- Stage 1: install Composer dependencies ----------
FROM composer:latest AS vendor
WORKDIR /app
COPY app/composer.json app/composer.lock ./
RUN composer install \
    --no-dev \
    --no-scripts \
    --no-interaction \
    --optimize-autoloader \
    --no-progress

# ---------- Stage 2: runtime image ----------
FROM php:8.3-fpm AS app

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

# 4. Copy Composer itself into the final image (kept, so `composer require` still works locally)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 5. Set the working directory
WORKDIR /var/www/html

# 6. Create a non-root user to run the application
RUN groupadd -g 1000 appuser && \
    useradd -u 1000 -g appuser -m appuser

# 7. Copy application code, owned by appuser (overridden locally by the bind mount)
COPY --chown=appuser:appuser app/ .

# 8. Copy the vendor/ built in Stage 1 (production dependencies only)
COPY --from=vendor --chown=appuser:appuser /app/vendor ./vendor

USER appuser