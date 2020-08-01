FROM php:5.4-apache

# PHP
RUN apt-get update && apt-get install -y \
      libicu-dev \
      libpq-dev \
      libmcrypt-dev \
      mysql-client \
      git \
      zip \
      unzip \
      libfreetype6-dev \
      libpng12-dev \
      libjpeg-dev \
    && rm -r /var/lib/apt/lists/* \
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install \
      intl \
      mbstring \
      mcrypt \
      pcntl \
      pdo_mysql \
      pdo_pgsql \
      pgsql \
      zip \
      gd

ENV APP_HOME /var/www/html

RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

RUN sed -i -e "s/html/html\/webroot/g" /etc/apache2/apache2.conf

RUN a2enmod rewrite

COPY . $APP_HOME

RUN chown -R www-data:www-data $APP_HOME

COPY php.ini /usr/local/etc/php/


# Install ImageMagick
WORKDIR /home

RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    vim

RUN wget https://www.imagemagick.org/download/ImageMagick.tar.gz
RUN tar xvzf ImageMagick.tar.gz
WORKDIR /home/ImageMagick-7.0.10-25
RUN ldconfig /usr/local/lib
RUN ./configure
RUN make
RUN make install
RUN ldconfig /usr/local/lib

# Support HEIC images
COPY sources.list /etc/apt/

RUN apt-get update && apt-get --yes --force-yes install \
    automake \
    libtool

WORKDIR /home
RUN git clone https://github.com/strukturag/libde265.git \
 && git clone https://github.com/strukturag/libheif.git

WORKDIR /home/libde265

RUN ./autogen.sh \
 && ./configure \
 && make -j4 \
 && make install

WORKDIR /home/libheif

RUN ./autogen.sh \
 && ./configure \
 && make -j4 \
 && make install

WORKDIR /home/ImageMagick-7.0.10-25

RUN ./configure --with-heic=yes \
 && make -j4 \
 && make install \
 && ldconfig

# Clean
RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /home/*

WORKDIR /var/www/html

