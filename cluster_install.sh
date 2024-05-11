#!/bin/bash

set -e

# Разворачиваем инфраструктуру в Yandex Cloud для кластера kubespray
cd terraform
TF_IN_AUTOMATION=1 terraform init
TF_IN_AUTOMATION=1 terraform apply -auto-approve
bash generate_inventory.sh > ../kubespray_inventory/hosts.ini
bash generate_credentials_velero.sh > ../kubespray_inventory/credentials-velero
bash generate_etc_hosts.sh > ../kubespray_inventory/etc-hosts

# Копируем каталог mycluster где будет создан файл Hosts для Ansible с адресами серверов где будет развёрнут kubespray 
cd ../
rm -rf kubespray/inventory/mycluster
cp -rfp kubespray_inventory kubespray/inventory/mycluster

# Разварачиваем кластер kubespray
cd kubespray
ansible-playbook -i inventory/mycluster/hosts.ini --become cluster.yml

# выводим все IP адреса
cd ../terraform
MASTER_1_PRIVATE_IP=$(terraform output -json instance_group_masters_private_ips | jq -j ".[0]")
MASTER_1_PUBLIC_IP=$(terraform output -json instance_group_masters_public_ips | jq -j ".[0]")

# создаём файл admin.conf для подключения к кластеру kubespray
sed -i -- "s/$MASTER_1_PRIVATE_IP/$MASTER_1_PUBLIC_IP/g" ../kubespray/inventory/mycluster/artifacts/admin.conf

# создаём каталог для управления кластера kubespray
mkdir -p ~/.kube

# копируем файл управления кластером admin.conf в каталог ~/.kube
cd ../
cp kubespray/inventory/mycluster/artifacts/admin.conf ~/.kube/config

# Копируем конфиг кластера для отработки CI-CD скриптов
mkdir -p /opt/.kube
cp kubespray/inventory/mycluster/artifacts/admin.conf /opt/.kube/config
chmod 777 /opt/.kube
chmod 777 /opt/.kube/config

# Добавляем сгенерированные хосты в наш локальный hosts-файл
sh -c "cat kubespray_inventory/etc-hosts >> /etc/hosts"

# Устанавливаем при помощи ansible на сервер srv роли docker docker-compose gitlab-runner
ansible-playbook -i config_srv/hosts --become config_srv/install.yaml

# Поверяем установленные docker docker-compose gitlab-runner
echo -n " "
echo -n "==================== Версия docker =============================="
echo -n " "
docker -v
echo -n " "
echo -n "==================== Версия docker-compose =============================="
echo -n " "
docker-compose -v
echo -n " "
echo -n "==================== Версия gitlab-runner =============================="
echo -n " "
gitlab-runner -v

# Проверяем кластер
echo -n " "
echo -n "==================== Ноды кластера =============================="
echo -n " "
kubectl get nodes

echo -n " "
echo -n "===== Если вы видете данное сообщение, значит кластер успешно установлен и настроен ======"
echo -n " "
