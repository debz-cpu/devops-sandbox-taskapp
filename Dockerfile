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

RUN apt-get update && apt-get install -y \
    libicu-dev \
    libonig-dev \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install \
    pdo_mysql \
    intl \
    mbstring

RUN sed -i \
    -e "s/^user = .*/user = appuser/" \
    -e "s/^group = .*/group = appuser/" \
    /usr/local/etc/php-fpm.d/www.conf

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

RUN groupadd -g 1000 appuser && \
    useradd -u 1000 -g appuser -m appuser

COPY --chown=appuser:appuser app/ .

# ---------- Stage 4: test image (used by CI — includes dev tools) ----------
FROM base AS test
COPY --from=vendor-dev --chown=appuser:appuser /app/vendor ./vendor
USER appuser

# ---------- Stage 5: production image (default, lean) ----------
FROM base AS app
COPY --from=vendor-prod --chown=appuser:appuser /app/vendor ./vendor
USER appuser
