# xUndero_infra
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
