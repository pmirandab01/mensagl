#!/bin/bash

# POSTGRE maestro

# Variables
DB_NAME="ejabberd_db"
DB_USER="ejabberd"
DB_PASS="admin123"  

# Actualizar paquetes e instalar PostgreSQL
sudo apt update && sudo apt install -y postgresql postgresql-contrib

# Iniciar y habilitar el servicio de PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Crear base de datos y usuario con permisos de superusuario
sudo -i -u postgres psql <<EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';
ALTER USER $DB_USER WITH SUPERUSER;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOF

# Configurar PostgreSQL como servidor maestro
PG_HBA="/etc/postgresql/$(ls /etc/postgresql)/main/pg_hba.conf"
POSTGRESQL_CONF="/etc/postgresql/$(ls /etc/postgresql)/main/postgresql.conf"

# Permitir conexiones remotas
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*' /" "$POSTGRESQL_CONF"

# Configurar acceso para replicación
echo "host replication all 0.0.0.0/0 md5" | sudo tee -a "$PG_HBA"
echo "host all all 0.0.0.0/0 md5" | sudo tee -a "$PG_HBA"

# Reiniciar PostgreSQL para aplicar cambios
sudo systemctl restart postgresql

# Mensaje de éxito
echo "PostgreSQL instalado, configurado como servidor maestro."
