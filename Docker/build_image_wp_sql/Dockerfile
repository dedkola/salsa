FROM ubuntu:20.04

# Set environment variables to avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    apache2 \
    mysql-server \
    php \
    php-mysql \
    libapache2-mod-php \
    curl \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*
RUN a2enmod rewrite
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf

# Install Adminer
RUN mkdir -p /var/www/html/adminer \
    && wget https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php \
    -O /var/www/html/adminer/index.php

# Set up MySQL
COPY my.cnf /etc/mysql/my.cnf
COPY db.sql /docker-entrypoint-initdb.d/db.sql
RUN service mysql start \
    && mysql -e "CREATE USER 'usr'@'%' IDENTIFIED BY '123';" \
    && mysql -e "CREATE DATABASE db1;" \
    && mysql -e "GRANT ALL PRIVILEGES ON db1.* TO 'usr'@'%';" \
    && mysql db1 < /docker-entrypoint-initdb.d/db.sql

 # Remove default index.html
RUN rm /var/www/html/index.html

    # Install WordPress
#RUN curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz \
#    && tar -xzf wordpress.tar.gz -C /var/www/html \
#    && mv /var/www/html/wordpress/* /var/www/html/ \
#    && rm -rf /var/www/html/wordpress wordpress.tar.gz

# Copy custom WordPress files
COPY wordpress_data /var/www/html/

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose ports
EXPOSE 80 3306

# Start services
CMD service mysql start && apachectl -D FOREGROUND
