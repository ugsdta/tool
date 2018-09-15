#!/bin/bash
set -ex

if [ -f /var/lib/mysql/mysqld-slow.log ]; then
    sudo mv /var/lib/mysql/mysqld-slow.log /var/lib/mysql/mysqld-slow.log.$(date "+%Y%m%d_%H%M%S")
fi
if [ -f /var/log/mysql/mysqld-slow.log ]; then
    sudo mv /var/log/mysql/mysqld-slow.log /var/log/mysql/mysqld-slow.log.$(date "+%Y%m%d_%H%M%S")
fi
if [ -f /var/log/nginx/access.log ]; then
    sudo mv /var/log/nginx/access.log /var/log/nginx/access.log.$(date "+%Y%m%d_%H%M%S")
fi

sudo systemctl restart mysql
#sudo service memcached restart
sudo systemctl restart redis-server
sudo systemctl restart isuxi.ruby
sudo systemctl restart nginx
