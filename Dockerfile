# Base PHP image
FROM php:8.3-fpm

# Install system dependencies
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

# Clear apt cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd intl zip

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy the entire project
COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Build Filament assets (v3 — NO --force)
RUN php artisan filament:assets

# Build Vite assets
RUN npm install
RUN npm run build

# Fix permissions
RUN chmod -R 775 storage bootstrap/cache

# Expose port (Railway uses 8080)
EXPOSE 8080

# Start Laravel production server
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8080"]
