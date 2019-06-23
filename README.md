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
