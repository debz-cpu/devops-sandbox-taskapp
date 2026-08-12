# ---------- Stage 1: install ALL Composer dependencies (dev + prod) ----------
FROM composer:latest AS vendor-dev
WORKDIR /app
COPY app/composer.json app/composer.lock ./
RUN composer install \
    --no-scripts \
    --no-interaction \
    --no-progress

# ---------- Stage 2: install PRODUCTION-ONLY Composer dependencies ----------
FROM composer:latest AS vendor-prod
WORKDIR /app
COPY app/composer.json app/composer.lock ./
RUN composer install \
    --no-dev \
    --no-scripts \
    --no-interaction \
    --optimize-autoloader \
    --no-progress

# ---------- Stage 3: shared runtime base ----------
FROM php:8.3-fpm AS base

# 1. Install system dependencies required for PHP extensions
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libonig-dev \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 2. Install the required PHP extensions (including OPcache)
RUN docker-php-ext-install \
    pdo_mysql \
    intl \
    mbstring \
    opcache

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

# ---------- Stage 4: test image (used by CI — includes dev tools, default OPcache) ----------
FROM base AS test
COPY --from=vendor-dev --chown=appuser:appuser /app/vendor ./vendor
USER appuser

# ---------- Stage 5: production image (default, lean, OPcache tuned) ----------
FROM base AS app

# Production OPcache tuning — NOT applied to test/dev, since
# validate_timestamps=0 would hide local code changes made via bind mount
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.revalidate_freq=0'; \
    echo 'opcache.validate_timestamps=0'; \
    echo 'opcache.enable_cli=0'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

COPY --from=vendor-prod --chown=appuser:appuser /app/vendor ./vendor
USER appuser
