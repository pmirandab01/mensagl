#!/bin/bash

# 28/01/2025
# Script combinado para la creación de VPC, subredes, gateways y Security Groups con NAT Gateway

# VARIABLES
VPC_NAME="reto25-equipo3-pablomm-vpc"
CIDR_BLOCK="10.222.0.0/16"
REGION="us-east-1"

# Crear una VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block $CIDR_BLOCK \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value='$VPC_NAME'}]' \
  --query 'Vpc.VpcId' --output text)
echo "VPC creada: $VPC_ID"

# Habilitar DNS hostname
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames

# Crear subredes
SUBNET_PUBLIC_1=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block "10.222.1.0/24" --availability-zone "$REGION"a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public1}]' \
  --query 'Subnet.SubnetId' --output text)
echo "Subred pública 1 creada: $SUBNET_PUBLIC_1"

SUBNET_PUBLIC_2=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block "10.222.2.0/24" --availability-zone "$REGION"b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public2}]' \
  --query 'Subnet.SubnetId' --output text)
echo "Subred pública 2 creada: $SUBNET_PUBLIC_2"

SUBNET_PRIVATE_1=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block "10.222.3.0/24" --availability-zone "$REGION"a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private1}]' \
  --query 'Subnet.SubnetId' --output text)
echo "Subred privada 1 creada: $SUBNET_PRIVATE_1"

SUBNET_PRIVATE_2=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block "10.222.4.0/24" --availability-zone "$REGION"b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private2}]' \
  --query 'Subnet.SubnetId' --output text)
echo "Subred privada 2 creada: $SUBNET_PRIVATE_2"

# Crear y asociar un Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=InternetGateway}]' \
  --query 'InternetGateway.InternetGatewayId' --output text)
echo "Internet Gateway creado: $IGW_ID"

aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

# Crear una Elastic IP para el NAT Gateway
EIP_NAT=$(aws ec2 allocate-address --domain "vpc" --query 'AllocationId' --output text)
echo "Elastic IP para NAT Gateway creado: $EIP_NAT"

# Crear el NAT Gateway en una subred pública
NAT_GATEWAY_ID=$(aws ec2 create-nat-gateway --subnet-id $SUBNET_PUBLIC_1 --allocation-id $EIP_NAT \
  --query 'NatGateway.NatGatewayId' --output text)
echo "NAT Gateway creado: $NAT_GATEWAY_ID"

# Esperar a que el NAT Gateway esté disponible
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GATEWAY_ID
echo "NAT Gateway está listo."

# Crear tabla de rutas públicas
RTB_PUBLIC=$(aws ec2 create-route-table --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=PublicRouteTable}]' \
  --query 'RouteTable.RouteTableId' --output text)
echo "Tabla de rutas públicas creada: $RTB_PUBLIC"

aws ec2 create-route --route-table-id $RTB_PUBLIC --destination-cidr-block "0.0.0.0/0" --gateway-id $IGW_ID
aws ec2 associate-route-table --route-table-id $RTB_PUBLIC --subnet-id $SUBNET_PUBLIC_1
aws ec2 associate-route-table --route-table-id $RTB_PUBLIC --subnet-id $SUBNET_PUBLIC_2

# Crear tabla de rutas privadas y asociar el NAT Gateway
RTB_PRIVATE=$(aws ec2 create-route-table --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=PrivateRouteTable}]' \
  --query 'RouteTable.RouteTableId' --output text)
echo "Tabla de rutas privadas creada: $RTB_PRIVATE"

aws ec2 create-route --route-table-id $RTB_PRIVATE --destination-cidr-block "0.0.0.0/0" --nat-gateway-id $NAT_GATEWAY_ID
echo "Ruta agregada para el NAT Gateway en la tabla privada."

aws ec2 associate-route-table --route-table-id $RTB_PRIVATE --subnet-id $SUBNET_PRIVATE_1
aws ec2 associate-route-table --route-table-id $RTB_PRIVATE --subnet-id $SUBNET_PRIVATE_2

echo "Infraestructura de VPC con NAT Gateway creada correctamente."

# ------------------------------------------------------------------------------ !

# Script de Security Groups

# Crear Security Group para servidor Ejabberd
SG_EJABBERD=$(aws ec2 create-security-group \
  --group-name SG-Ejabberd \
  --description "SG para servidor Ejabberd" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)
echo "Security Group Ejabberd creado: $SG_EJABBERD"

# Reglas de entrada para Ejabberd
aws ec2 authorize-security-group-ingress --group-id $SG_EJABBERD --protocol tcp --port 5222 --cidr 0.0.0.0/0
echo "Permitido tráfico en puerto 5222 (XMPP Cliente)"

aws ec2 authorize-security-group-ingress --group-id $SG_EJABBERD --protocol tcp --port 5269 --cidr 0.0.0.0/0
echo "Permitido tráfico en puerto 5269 (XMPP Servidor)"

aws ec2 authorize-security-group-ingress --group-id $SG_EJABBERD --protocol tcp --port 5280 --cidr 0.0.0.0/0
echo "Permitido tráfico en puerto 5280 (Interfaz Web de Administración)"

aws ec2 authorize-security-group-ingress --group-id $SG_EJABBERD --protocol tcp --port 22 --cidr 0.0.0.0/0
echo "Permitido tráfico SSH desde cualquier IP"

# Crear Security Group para PostgreSQL
SG_POSTGRESQL=$(aws ec2 create-security-group \
  --group-name SG-PostgreSQL \
  --description "SG para base de datos PostgreSQL" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)
echo "Security Group PostgreSQL creado: $SG_POSTGRESQL"

# Reglas de entrada para PostgreSQL
aws ec2 authorize-security-group-ingress --group-id $SG_POSTGRESQL --protocol tcp --port 5432 --source-group $SG_EJABBERD
echo "Permitido tráfico en puerto 5432 desde Ejabberd"

aws ec2 authorize-security-group-ingress --group-id $SG_POSTGRESQL --protocol tcp --port 22 --cidr 0.0.0.0/0
echo "Permitido tráfico SSH desde cualquier IP"

# Crear Security Group para CMS
SG_CMS=$(aws ec2 create-security-group \
  --group-name SG-CMS \
  --description "SG para servidor CMS (WordPress)" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)
echo "Security Group CMS creado: $SG_CMS"

# Reglas de entrada para CMS
aws ec2 authorize-security-group-ingress --group-id $SG_CMS --protocol tcp --port 80 --cidr 0.0.0.0/0
echo "Permitido tráfico HTTP (puerto 80)"

aws ec2 authorize-security-group-ingress --group-id $SG_CMS --protocol tcp --port 443 --cidr 0.0.0.0/0
echo "Permitido tráfico HTTPS (puerto 443)"

aws ec2 authorize-security-group-ingress --group-id $SG_CMS --protocol tcp --port 22 --cidr 0.0.0.0/0
echo "Permitido tráfico SSH desde cualquier IP"

# Crear Security Group para MySQL
SG_MYSQL=$(aws ec2 create-security-group \
  --group-name SG-MySQL \
  --description "SG para base de datos MySQL" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)
echo "Security Group MySQL creado: $SG_MYSQL"

# Reglas de entrada para MySQL
aws ec2 authorize-security-group-ingress --group-id $SG_MYSQL --protocol tcp --port 3306 --source-group $SG_CMS
echo "Permitido tráfico en puerto 3306 desde CMS"

aws ec2 authorize-security-group-ingress --group-id $SG_MYSQL --protocol tcp --port 22 --cidr 0.0.0.0/0
echo "Permitido tráfico SSH desde cualquier IP"

# ------------------------------------------------------------------------------ !

# Script para lanzar instancias EC2 con NAT Gateway habilitado para las subredes privadas

# AMI de Ubuntu Server 24.04 LTS (ID puede variar por región, ajusta según sea necesario)
AMI_ID="ami-04b4f1a9cf54c11d0" # Reemplaza con la AMI correcta de Ubuntu 24.04
INSTANCE_TYPE="t2.micro"
KEY_NAME="reto25-equipo3-pablomm"
KEY_FILE="$KEY_NAME.pem"

# Verificar si la clave SSH ya existe
if ! aws ec2 describe-key-pairs --key-names "$KEY_NAME" >/dev/null 2>&1; then
  echo "Clave SSH no encontrada, creando una nueva..."
  aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "$KEY_FILE"
  chmod 400 "$KEY_FILE"
  echo "Clave SSH creada y guardada como $KEY_FILE"
else
  echo "Clave SSH $KEY_NAME ya existe."
fi

# Crear instancia Ejabberd en la subred pública 1
INSTANCE_EJABBERD=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --subnet-id $SUBNET_PUBLIC_1 \
  --private-ip-address 10.222.1.10 \
  --security-group-ids $SG_EJABBERD \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=equipo3-ejabberd}]' \
  --associate-public-ip-address \
  --query 'Instances[0].InstanceId' --output text)
echo "Instancia Ejabberd creada: $INSTANCE_EJABBERD"

# Crear instancia PostgreSQL en la subred privada 1
INSTANCE_POSTGRES=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --subnet-id $SUBNET_PRIVATE_1 \
  --private-ip-address 10.222.3.100 \
  --security-group-ids $SG_POSTGRESQL \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=equipo3-postgresql}]' \
  --query 'Instances[0].InstanceId' --output text)
echo "Instancia PostgreSQL creada: $INSTANCE_POSTGRES"

# Crear instancia CMS (WordPress) en la subred pública 2
INSTANCE_CMS=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --subnet-id $SUBNET_PUBLIC_2 \
  --private-ip-address 10.222.2.10 \
  --security-group-ids $SG_CMS \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=equipo3-cms}]' \
  --associate-public-ip-address \
  --query 'Instances[0].InstanceId' --output text)
echo "Instancia CMS creada: $INSTANCE_CMS"

# Crear instancia MySQL en la subred privada 2
INSTANCE_MYSQL=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --subnet-id $SUBNET_PRIVATE_2 \
  --private-ip-address 10.222.4.100 \
  --security-group-ids $SG_MYSQL \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=equipo3-mysql}]' \
  --query 'Instances[0].InstanceId' --output text)
echo "Instancia MySQL creada: $INSTANCE_MYSQL"

# Fin del script
echo "Todas las instancias EC2 han sido creadas correctamente con acceso a Internet para las privadas a través del NAT Gateway."
echo "Infraestructura creada correctamente"
