FROM php:8.2-apache

# تثبيت extensions المطلوبة
RUN docker-php-ext-install pdo pdo_mysql mysqli

# نسخ الملفات
COPY . /var/www/html/

# صلاحيات
RUN chown -R www-data:www-data /var/www/html

# Railway بيحدد PORT ديناميكياً
RUN echo 'Listen ${PORT}' > /etc/apache2/ports.conf
RUN echo '<VirtualHost *:${PORT}>\n\
    DocumentRoot /var/www/html\n\
    <Directory /var/www/html>\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

EXPOSE 8080

CMD ["apache2-foreground"]
