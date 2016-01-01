# docker-bareos-mysql
Bareos on Docker 

Bareos is a fork of the well know backup solution "Bacula"
see https://www.bareos.org

This Bareos installation on Docker comes with integrated mysql backend and Bareos Webui.
Database files and configuration are mapped to volumes

##build

docker build -t tommi2day/bareos-mysql .

##run 

see run_bareos-mysql.sh
