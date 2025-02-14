#!/bin/bash

# POSTGREE ESCLAVO

# Actualizar paquetes e instalar PostgreSQL
sudo apt update && sudo apt install -y postgresql postgresql-contrib

# Iniciar PostgreSQL en modo esclavo
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Mensaje de éxito
echo "PostgreSQL instalado"
