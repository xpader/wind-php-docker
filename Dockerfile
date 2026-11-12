FROM php:8.1.34-cli-alpine3.21
LABEL maintainer="Pader <ypnow@163.com>" version="1.1.1"

ARG timezone
ENV TIMEZONE=${timezone:-"Asia/Shanghai"}

# basic system
RUN set -ex \
    && sed -i "s/dl-cdn.alpinelinux.org/mirrors.huaweicloud.com/g" /etc/apk/repositories \
    && apk update \
    && apk add --no-cache tzdata htop \
    # config timezone
    && ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone

# install php extensions
RUN apk add --no-cache $PHPIZE_DEPS pcre pcre-dev gmp gmp-dev zlib zlib-dev libzip libzip-dev libpng libpng-dev libjpeg-turbo libjpeg-turbo-dev libwebp libwebp-dev libevent libevent-dev openssl openssl-dev \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install bcmath gmp calendar exif sockets pcntl zip gd \
    # install pecl extensions
    && pecl install -n ev && docker-php-ext-enable ev.so \
    && pecl install -n event && docker-php-ext-enable event.so \
    # event.so needs socket_import_file_descriptor from the sockets extension.
    # PHP loads conf.d files alphabetically, so event (e) would load before
    # sockets (s) and fail to resolve the symbol. Prefix sockets' ini with
    # 00- to force it to load first.
    && mv /usr/local/etc/php/conf.d/docker-php-ext-sockets.ini /usr/local/etc/php/conf.d/00-docker-php-ext-sockets.ini \
    # clean
    && apk del $PHPIZE_DEPS pcre-dev gmp-dev zlib-dev libzip-dev libpng-dev libjpeg-turbo-dev libwebp-dev libevent-dev openssl-dev \
    # show php version and extensions
    && php -v \
    && php -m

# install composer
RUN wget -O /usr/local/bin/composer https://mirrors.aliyun.com/composer/composer.phar \
    && chmod 755 /usr/local/bin/composer \
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ \
    && echo -e "\033[42;37m Build Completed :)\033[0m\n"

#COPY php.ini /usr/local/etc/php/

USER www-data
WORKDIR /home/www-data
# COPY --chown=www-data:www-data . /home/www-data/

CMD ["php", "start.php", "start"]
