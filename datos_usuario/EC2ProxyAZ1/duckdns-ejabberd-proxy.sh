#!/bin/bash

# Configuración
DOMAIN="ejabberdpmm"
TOKEN="6b4a8e59-621e-4151-8e3a-5a862cabedaa"
DUCKDNS_DIR="/opt/duckdns"

# Crear directorio para DuckDNS
mkdir -p $DUCKDNS_DIR
cd $DUCKDNS_DIR

# Crear script de actualización
echo '#!/bin/bash
IP=$(curl -s https://api.ipify.org)
echo url="https://www.duckdns.org/update?domains='$DOMAIN'&token='$TOKEN'&ip=$IP" | curl -k -o duckdns.log -K -
' > duckdns.sh
chmod +x duckdns.sh

# Ejecutar el script de actualización inicialmente
./duckdns.sh

# Agregar al crontab para actualizar cada 5 minutos
(crontab -l 2>/dev/null; echo "* * * * * $DUCKDNS_DIR/duckdns.sh >/dev/null 2>&1") | crontab -

# Esperar hasta que el archivo de log indique "OK"
echo " Esperando a que DuckDNS complete la configuración..."
while true; do
    if [[ -f /opt/duckdns/duckdns.log ]] && grep -q "OK" /opt/duckdns/duckdns.log; then
        echo "✅ DuckDNS configurado correctamente."
        break
    fi
    sleep 2  # Espera 2 segundos antes de volver a verificar
done

echo "DuckDNS configurado correctamente para $DOMAIN"
