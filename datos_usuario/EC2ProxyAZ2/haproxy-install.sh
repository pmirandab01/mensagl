#!/bin/bash

echo "Instalando HAProxy"
sudo apt install haproxy -y

# Mover configuración de HAProxy
echo "Configurando HAProxy..."
sudo mv haproxy.cfg /etc/haproxy/haproxy.cfg

# Reiniciar HAProxy para aplicar los cambios
echo "Reiniciando HAProxy..."
sudo systemctl restart haproxy

echo "Proceso completado exitosamente."
