#!/bin/bash
# RDS 

STACK_VPC="vpc-mensagl-2025-PABLOMIRANDA"
STACK_SG="equipo3-sg"

SG_DB_CMS_ID=$(aws cloudformation describe-stacks --stack-name "$STACK_SG" --query "Stacks[0].Outputs[?ExportName=='equipo3-SG-RDS-ID'].OutputValue" --output text)

if [ -z "$SG_DB_CMS_ID" ]; then
  echo "Error: No se pudo obtener el Security Group de la base de datos RDS."
  exit 1
fi


echo "Creando grupo de subredes para RDS MySQL"
    
RDS_SUBNET_GROUP_NAME="cms-db-subnet-group"
SUBNET_PRIVATE1_ID=$(aws cloudformation describe-stacks --stack-name "$STACK_VPC" --query "Stacks[0].Outputs[?ExportName=='equipo3-SubnetPrivate1-ID'].OutputValue" --output text)
SUBNET_PRIVATE2_ID=$(aws cloudformation describe-stacks --stack-name "$STACK_VPC" --query "Stacks[0].Outputs[?ExportName=='equipo3-SubnetPrivate2-ID'].OutputValue" --output text)

if [ -z "$SUBNET_PRIVATE1_ID" ] || [ -z "$SUBNET_PRIVATE2_ID" ]; then
  echo "Error: No se pudieron obtener las subredes privadas de la VPC."
  exit 1
fi

# Verificar si el grupo de subredes ya existe
EXISTING_SUBNET_GROUP=$(aws rds describe-db-subnet-groups --query "DBSubnetGroups[?DBSubnetGroupName=='cms-db-subnet-group'].DBSubnetGroupName" --output text)

if [ "$EXISTING_SUBNET_GROUP" == "cms-db-subnet-group" ]; then
  echo "El grupo de subredes ya existe, omitiendo creación."
else
  echo "Creando grupo de subredes para RDS MySQL..."
  aws rds create-db-subnet-group \
      --db-subnet-group-name "$RDS_SUBNET_GROUP_NAME" \
      --db-subnet-group-description "Grupo de subredes para RDS MySQL CMS" \
      --subnet-ids "$SUBNET_PRIVATE1_ID" "$SUBNET_PRIVATE2_ID" \
      --tags Key=Name,Value="$RDS_SUBNET_GROUP_NAME"
  echo "Grupo de subredes creado exitosamente."
fi

# Crear instancia RDS MySQL
echo "Creando instancia de RDS MySQL..."
aws rds create-db-instance \
    --db-instance-identifier "cms-database" \
    --allocated-storage 20 \
    --storage-type "gp2" \
    --db-instance-class "db.t3.micro" \
    --engine "mysql" \
    --engine-version "8.0" \
    --master-username "admin" \
    --master-user-password "Admin123" \
    --db-name "wordpress_db" \
    --db-subnet-group-name "$RDS_SUBNET_GROUP_NAME" \
    --vpc-security-group-ids "$SG_DB_CMS_ID" \
    --tags Key=Name,Value="wordpress_db"
echo "Instancia RDS MySQL creada exitosamente."



