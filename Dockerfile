FROM php:8.3-apache

# Enable the rewrite module and set the server name to silence warnings.
RUN a2enmod rewrite \
    && echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf \
    && a2enconf servername

COPY index.php /var/www/html/index.php

EXPOSE 80
