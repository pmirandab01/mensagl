#!/bin/bash
#!/bin/bash

# Variables
db_name="wordpress_db"
db_user="wp_user"
db_password="admin"
wp_dir="/var/www/html/wordpress"
wp_url="https://wordpress.org/latest.tar.gz"

# Actualizar paquetes
sudo apt update && sudo apt upgrade -y

# Instalar Apache, MySQL y PHP
sudo apt install -y apache2 mysql-server php php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip unzip curl

# Habilitar mod_rewrite y reiniciar Apache
sudo a2enmod rewrite
sudo systemctl restart apache2

# Configurar MySQL (crear DB y usuario)
sudo mysql -e "CREATE DATABASE ${db_name};"
sudo mysql -e "CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_password}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Descargar y configurar WordPress
sudo rm -rf ${wp_dir}
sudo mkdir -p ${wp_dir}
sudo wget -q ${wp_url} -O /tmp/wordpress.tar.gz
sudo tar -xzf /tmp/wordpress.tar.gz -C /var/www/html/

# Configurar permisos
sudo chown -R www-data:www-data ${wp_dir}
sudo chmod -R 755 ${wp_dir}

# Configurar wp-config.php
sudo cp ${wp_dir}/wp-config-sample.php ${wp_dir}/wp-config.php
sudo sed -i "s/database_name_here/${db_name}/g" ${wp_dir}/wp-config.php
sudo sed -i "s/username_here/${db_user}/g" ${wp_dir}/wp-config.php
sudo sed -i "s/password_here/${db_password}/g" ${wp_dir}/wp-config.php

# Reiniciar Apache
sudo systemctl restart apache2

# Mensaje final
echo "✅ WordPress instalado en ${wp_dir}. Accede a tu dominio o IP pública para completar la instalación."
