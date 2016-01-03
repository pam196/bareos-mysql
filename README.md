# docker-bareos-mysql
## Bareos on Docker 

Bareos is a fork of the well know backup solution "Bacula"
see https://www.bareos.org

This Bareos installation on Docker comes with integrated mysql backend and Bareos Webui.
Database files and configuration are mapped to volumes

### build
```sh
docker build -t tommi2day/bareos-mysql .
```
### exposed Ports
```sh
# web, director, fd, storage, mysql daemons 
EXPOSE 80 9101 9102 9103 3306
```
### Volumes
```sh
VOLUME /db # mysql datadir
VOLUME /var/log/mysql # mysql logfiles
VOLUME /var/log/apache2 # apache logfiles
VOLUME /backup # Backup Storage
VOLUME ["/etc/bareos","/var/log/bareos","/etc/bareos-webui"] # Bareos konfiguration
```
### Environment variables used
```sh
TARGET_HOST # Host/IP for bareos dir, fd and sd Address configuration parameter  
BAREOS_DB_PASSWORD # create bareos user account with this password
DB_ROOT_PASSWORD # create database with this password 
```
### run 
Variables may be predifined within run.vars, see run_bareos-mysql.sh. 
```sh
docker run --name bareos-mysql \
--add-host="bareos:127.0.0.1" \
-e TARGET_HOST=$TARGET_HOST \
-e BAREOS_DB_PASSWORD=$BAREOS_DB_PASSWORD \
-e DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD \
-v ${BACKUP_DIR}:/backup \
-v ${SHARED_DIR}/db:/db \
-v ${SHARED_DIR}/etc-bareos:/etc/bareos \
-v ${SHARED_DIR}/log-mysql:/var/log/mysql \
-v ${SHARED_DIR}/log-bareos:/var/log/bareos \
-v ${SHARED_DIR}/etc-bareos-webui:/etc/bareos-webui \
-v ${SHARED_DIR}/log-apache2:/var/log/apache2 \
-p ${EXT_DIR_PORT}:9101 -p ${EXT_FD_PORT}:9102 -p ${EXT_SD_PORT}:9103 \
-p ${EXT_DB_PORT}:3306 -p ${EXT_HTML_PORT}:80 \
tommi2day/bareos-mysql
```

#### local settings
* bareos.env --> will be sourced each time container starts. You may place your mailconfig or others there, with is not persistent in the container
```sh
#bareos env system configuration
#will be executed on every start by prepare.sh
#put your local system changes here
#mail
postconf -e relayhost=mailhost
postconf -e myhostname=bareos
echo "
root:         root@mydomain.com
" >>/etc/aliases
newaliases
postfix restart

#Time
echo "Europe/Berlin" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
ntpdate -q ptbtime1.ptb.de

```
* run.vars --> defines variables used by run_bareos-mysql.sh
```sh
#runtime variables
#DOCKER_SHARED=$(pwd)}
#SHARED_DIR=bareos-shared
BACKUP_DIR=/volume1/Backup/bareos
#TARGET_HOST=docker
BAREOS_DB_PASSWORD=bareos
DB_ROOT_PASSWORD=supersecret
EXT_HTML_PORT=33080
#EXT_DB_PORT=3306
#EXT_DIR_PORT=9101
#EXT_FD_PORT=9102
#EXT_SD_PORT=9103
```
