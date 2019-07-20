# xUndero_infra
## ДЗ №3 cloud-bastion
1. ##### Регистрация на GCP и создание виртуальных машин:


	В результате получились машины со следующими адресами:

	bastion_IP = 35.195.253.177
	someinternalhost_IP = 10.132.0.3
2. ##### Подключение по SSH


	Для подключения к someinternalhost в одну строку использовалась команда:

	ssh -i ~/.ssh/appuser -A -t appuser@35.195.253.177 ssh appuser@10.132.0.3

	А для подключения по алиасу в файл ~/.ssh/config добавлено следующее:

	Host someinternalhost
		IdentityFile ~/.ssh/appuser
		User appuser
		Hostname 10.132.0.3
		ProxyCommand ssh -W %h:%p appuser@35.195.253.177

######	А после упоминания Владимира про ProxyJump и такие варианты:
    
    ssh -i ~/.ssh/appuser -J appuser@35.195.253.177 appuser@10.132.0.3
    
	Host someinternalhost
		IdentityFile ~/.ssh/appuser
		User appuser
		Hostname 10.132.0.3
		ProxyJump appuser@35.195.253.177
3. ##### Создание VPN и подключение


	Для создания был склонирован репозиторий с файлом setupvpn.sh:
    
    git clone https://gist.github.com/df07e99e63e4043e6a699060a7e30b66.git
    
    Затем, после установки и создания сервера и пользователя бдл запущен vpn клиент:
    
    sudo openvpn --config ./cloud-bastion.ovpn
    
    И проверка подключения прошла успешно ssh -i ~/.ssh/appuser appuser@10.132.0.3
    
    Сервисами sslip/xip я не пользовался. Просто вначале для удобства я в существующем домене создал запись типа A bastion.<mydomain>.ru а затем в настройках PritunL в поле Lets Encrypt Domain указал это доменное имя и получил SSL сертификат.

## ДЗ №4 cloud-testapp
1. ##### Создание ВМ с помощью *`gcloud`* и развёртывание приложения:
В результате получились следующие значения:  

    testapp_IP = 34.77.167.102
    testapp_port = 9292
2. ##### Создание скриптов автоматического развёртывания:
Используемые ранее команды были оформлены в виде трёх скриптов:  
***install_ruby.sh:***

    #!/bin/bash
    sudo apt update
    sudo apt install -y ruby-full ruby-bundler build-essential
    ruby -v
    bundler -v
***install_mongodb.sh:***

    #!/bin/bash
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
    sudo bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'
    sudo apt update
    sudo apt install -y mongodb-org
    sudo systemctl start mongod
    sudo systemctl enable mongod
    sudo systemctl status mongod
***deploy.sh:***

    #!/bin/bash
    cd ~
    git clone -b monolith https://github.com/express42/reddit.git
    cd reddit && bundle install
    puma -d
    ps aux | grep puma
Скрипты сперва запускались в ручном режиме после создания ВМ, затем были объединены в один и указан при создании ВМ:

    gcloud compute instances create reddit-app1 \
    --boot-disk-size=10GB \
    --image-family ubuntu-1604-lts \
    --image-project=ubuntu-os-cloud \
    --machine-type=g1-small \
    --tags puma-server \
    --restart-on-failure \
    --metadata-from-file startup-script=/home/xunder/projects/xUndero_infra/reddit_script.sh
Затем был создан сегмент хранилища, скрипт скопирован туда и путь указан при создании ВМ:

    gcloud compute instances create reddit-app1 \
    --boot-disk-size=10GB \
    --image-family ubuntu-1604-lts \
    --image-project=ubuntu-os-cloud \
    --machine-type=g1-small \
    --tags puma-server \
    --restart-on-failure \
    --metadata startup-script-url=gs://storage-app/reddit_script.sh
3. ##### Создание правила файрвола:  
Правило было удалено через консоль и создано командой:

    gcloud compute firewall-rules create default-puma-server --allow tcp:9292 --target-tags=puma-server

## ДЗ №5 packer-base
1. ##### Создание шаблона packer и создание с помощью шаблона экземпляра ВМ:
2. ##### Изменение шаблона:
В шаблон были добавлены описания переменных для:

    project_id, source_image_family - без указания значений по умолчанию
    и machine_type с указанием значения по умолчанию
значения переменных вынесены в файл ***variables.json***,
Файл был скрыт с прмощью ***.gitignore***,
Пример заполнения представлен в ***variables.json.example***  

В шаблон добавлены параметры

    "disk_size": "11",
    "disk_type": "pd-ssd",
    "network": "default",
    "tags": "puma-server"
Хотя часть параметров касается временной ВМ для создания шаблона и не распространяется на создаваемый экземпляр ВМ.

3. ##### Создание шаблона запускаемого приложения:
Создан дополнительный шаблон, в который копируется файл ***reddit.service***,  
затем с помощью скрипта ***deploy.sh*** устанавливаются зависимости и  
файл службы приложения копируется в ***/etc/systemd/system/*** и запускается.

4. ##### Запуск создания экземпляра ВМ:
Создан скрипт для создания ВМ:

    gcloud compute instances create reddit-app2 --image-family reddit-full --machine-type=g1-small --tags puma-server --restart-on-failure

## ДЗ №6 terraform-1
1. ##### Практика IaC с использованием terraform:

2. ##### Самостоятельные задания:
Дополнительно были созданы входные переменные для приватного ключа и зоны,
и создан файл ***terraform.tfvars.example***

3. ##### Добавление ssh ключей нескольких пользователей:

В коде добавлены ssh ключи в метаданные проекта:

    resource "google_compute_project_metadata" "default" {
      metadata = {
        ssh-keys = "appuser1:${file(var.public_key_path)}appuser2:${file(var.public_key_path)}appuser3:${file(var.public_key_path)}"
      }
    }

Ключ пользователя, добавленного через web terraform при следующем применении удаляет.

4. ##### Создание балансировщика нагрузки:
Сперва попробовал создать балансировщик через web.
Затем создал файл ***lb.tf***
При добавлении второго экземпляра проверил работу балансировщика. При добавлении второго экземпляра происходит дублирование кода.
Поэтому было переделано создание экземпляров с помощью параметра ***count***.

## ДЗ №7 terraform-2
1. ##### Дальнейшее изучение организации инфраструктуры:
  * Создание и импорт ресурсов на примере правила файрвола;
  * Взаимосвязь ресурсов;
  * Разбивка конфигурации на отдельные файлы;
  * Использование модулей

2. ##### Самостоятельные задания:
Создан модуль *`vpc`* main.tf:

    resource "google_compute_firewall" "firewall_ssh" {
    name        = "default-allow-ssh"
    description = "My ssh rule"
    network     = "default"
    
    allow {
      protocol = "tcp"
      ports    = ["22"]
    }
    
    source_ranges = "${var.source_ranges}"
    }
Модуль с параметром отрабатывает, в том числе и при использовании двух окружений.

3. ##### Работа с реестром модулей:
Storage-buckets созданы успешно.

4. ##### Настройка хранения файла состояния:
Создан файл ***backend.tf***:

    terraform {
      backend "gcs" {
        bucket = "storage-app"
        prefix = "prod"
      }
    }
В stage - соответственно prefix = "stage".
При работе terraform блокирует доступ к файлу состояния и при попытке запустить из другого места сообщает о блокировке (даже если только ждёт ответа yes)

5. ##### Запуск приложения:
  * db:

Образ db был пересоздан packer-ом с подменой файла конфигурации, разрешающего прослушивать адреса 0.0.0.0/0;
Также была создана выходная переменная:

    output "db_internal_ip" {
      value = "${google_compute_instance.db.network_interface.0.network_ip}"
    }
  * app:

Использованные ранее файлы *`puma.service и deploy.sh`* положены в ***../modules/app/files/***;  
В файле puma.service добавлена строка *`EnvironmentFile=/home/appuser/puma.env`*;  
Также добавлена переменная *`db_internal_ip`*, которая в корневом модуле определяется:

    db_internal_ip   = "${module.db.db_internal_ip}"

И включены следующие provisioners:

    provisioner "file" {
      source      = "../modules/app/files/puma.service"
      destination = "/tmp/puma.service"
    }
    
    provisioner "file" {
    content     = "DATABASE_URL=${var.db_internal_ip}"
    destination = "/home/appuser/puma.env"
    }
    
    provisioner "remote-exec" {
    script = "../modules/app/files/deploy.sh"
    }

# ДЗ №8 ansible-1
1. ##### Установка и знакомство с Ansible:
  * Создание inventory и файла cfg;
  * Группы хостов;
  * Использование YAML inventory;
  * Использование playbook-ов.
В последнем пункте при удалении каталога вручную и запуска playbook-а повторно состояние станет changed=1

2. ##### Самостоятельные задания:
Отличительной особенностью формата JSON для динамического inventory является наличие секции *`_meta`*
Для создания файла я использовал команду:

    ansible-inventory -i ./inventory.yml --list --output=./inventory.json
Т. к. сказано, что можно использовать данный файл), создал следующий скрипт:

    #!/bin/bash
    if [ $# -eq 0 ]
      then
      echo "Usage: script --list"
      exit 1
    fi
    if [ $1 = "--list" ]
      then
      cat ./inventory.json
    fi
                
