FROM php:8.3-fpm

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    nodejs \
    npm \
    libpng-dev \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    libicu-dev \
    zip

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd intl zip

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www
COPY . .

ENV APP_ENV=production
ENV APP_KEY=base64:X+wV86VcUvKwcKyBTHA3O7OFXlVmu+9e43DLiz2NRms=

# Clear Laravel caches
RUN php artisan optimize:clear

# Publish all Filament assets including fonts
RUN php artisan vendor:publish --tag=filament-public --force
RUN php artisan filament:assets

# Build Vite assets
RUN npm install
RUN npm run build

RUN chmod -R 775 storage bootstrap/cache

EXPOSE 8080

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8080"]
