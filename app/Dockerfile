# Optimized for 512MB RAM
FROM php:8.2.8-apache

# Declare build argument and set as environment variable
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION}

# Install PHP extensions (add opcache for performance!)
RUN docker-php-ext-install pdo_mysql opcache

# Install minimal tools and cleanup
RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip p7zip-full && \
    rm -rf /var/lib/apt/lists/*

# Installez Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copiez les fichiers de l'application dans le conteneur
COPY . /var/www/html/

# Install dependencies WITHOUT dev packages (saves 20-30MB)
RUN composer install --no-dev --optimize-autoloader --classmap-authoritative --no-interaction

# Copy optimized PHP configuration
COPY docker/php-production.ini /usr/local/etc/php/conf.d/zzz-production.ini

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

RUN chown -R www-data:www-data /var/www/html/vendor /var/www/html/storage /var/www/html/bootstrap /var/www/html/public /var/www/html/app /var/www/html/config /var/www/html/routes /var/www/html/resources
RUN chmod -R 755 /var/www/html/vendor /var/www/html/storage /var/www/html/bootstrap /var/www/html/public /var/www/html/app /var/www/html/config /var/www/html/routes /var/www/html/resources

# Modifiez la configuration d'Apache pour pointer vers le répertoire public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Enable Apache modules
RUN a2enmod rewrite

# Reduce Apache memory usage - CRITICAL for 512MB!
RUN echo '<IfModule mpm_prefork_module>' > /etc/apache2/mods-available/mpm_prefork.conf && \
    echo '    StartServers 1' >> /etc/apache2/mods-available/mpm_prefork.conf && \
    echo '    MinSpareServers 1' >> /etc/apache2/mods-available/mpm_prefork.conf && \
    echo '    MaxSpareServers 2' >> /etc/apache2/mods-available/mpm_prefork.conf && \
    echo '    MaxRequestWorkers 10' >> /etc/apache2/mods-available/mpm_prefork.conf && \
    echo '    MaxConnectionsPerChild 1000' >> /etc/apache2/mods-available/mpm_prefork.conf && \
    echo '</IfModule>' >> /etc/apache2/mods-available/mpm_prefork.conf

# Exposez le port 80
EXPOSE 80

# Use entrypoint script
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
