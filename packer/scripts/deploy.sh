#!/bin/bash
cd /home/appuser/
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
#cd /home/appuser/
#Install service
cp /tmp/reddit.service /etc/systemd/system/
systemctl enable reddit.service
systemctl start reddit.service
