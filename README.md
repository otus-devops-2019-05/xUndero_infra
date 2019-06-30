# xUndero_infra
## ДЗ №3 cloud-bastion
1. ##### Регистрация на GCP и создание виртуальных машин:


	В результате получились машины со следующими адресами:

	bastion_IP = 35.195.253.177
	someinternalhost_IP = 10.132.0.3
2.	##### Подключение по SSH


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
