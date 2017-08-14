FROM php:7.1-apache

RUN apt-get update \
  && apt-get install -y \
    git-core \
    libjpeg-dev \
    libmcrypt-dev \
    libmemcached-dev \
    libphp-predis \
    libpng12-dev \
    libpq-dev \
    libsqlite3-dev \
    libz-dev \
    vim \
  && rm -rf /var/lib/apt/lists/* \
  && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
  && docker-php-ext-install \
    gd \
    json \
    mbstring \
    mcrypt \
    mysqli \
    opcache \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    pdo_sqlite \
    zip \
  && pecl install memcached redis xdebug \
  && docker-php-ext-enable memcached redis xdebug

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
  } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN a2enmod rewrite expires

VOLUME /var/www/html

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
  && /usr/local/bin/composer global require hirak/prestissimo

ENV OCTOBERCMS_TAG v1.0.420
ENV OCTOBERCMS_CHECKSUM 13f7b11b2f062025697e5a93f5bc4dcb109daa07
ENV OCTOBERCMS_CORE_BUILD 420
ENV OCTOBERCMS_CORE_HASH 9c5af2e2c04126ed4fd4039c20d8bbb3

# Get October CMS src
RUN cd /usr/src \
  && curl -o octobercms.tar.gz -fSL https://codeload.github.com/octobercms/october/legacy.tar.gz/{$OCTOBERCMS_TAG} \
  && echo "$OCTOBERCMS_CHECKSUM *octobercms.tar.gz" | sha1sum -c - \
  && mkdir -p /usr/src/octobercms \
  && tar -xzf /usr/src/octobercms.tar.gz -C /usr/src/octobercms --strip 1 \
  && rm octobercms.tar.gz \
  && cd /usr/src/octobercms \
  && composer require --no-update --prefer-dist predis/predis \
  && composer install --no-interaction --prefer-dist --no-scripts \
  && php artisan october:env

# Get October CMS installer
RUN cd /usr/src && curl -o octobercms.install.tar.gz -fSL https://codeload.github.com/octobercms/install/legacy.tar.gz/master

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]