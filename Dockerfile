FROM php:8.3-fpm

# nginx serves on :80 and passes .php requests to PHP-FPM on 127.0.0.1:9000.
# supervisord keeps both processes running in this one container.
RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx supervisor \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/nginx/sites-enabled/default

COPY etc/nginx.conf /etc/nginx/conf.d/default.conf
COPY etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY index.php /var/www/html/index.php

EXPOSE 80

CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
