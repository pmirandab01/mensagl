#!/bin/bash

# Actualizamos la máquina
echo "Actualizando la máquina..."
sudo apt update

curl -o /etc/apt/sources.list.d/ejabberd.list https://repo.process-one.net/ejabberd.list
curl -o /etc/apt/trusted.gpg.d/ejabberd.gpg https://repo.process-one.net/ejabberd.gpg
apt update
apt install ejabberd
