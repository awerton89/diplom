#!/bin/bash

set -e

# удаляем каталог mycluster
rm -rf kubespray/inventory/mycluster

# Удаляем всю инфраструктуру 
cd terraform
TF_IN_AUTOMATION=1 terraform destroy -auto-approve

# удаляем каталог ~/.kube
rm -rf ~/.kube

# удаляем каталог /var/.kube
rm -rf /opt/.kube

# Результат удаления
echo -n " "
echo -n "===== Если вы видете данное сообщение, значит кластер успешно удалён  ======"
echo -n " "
