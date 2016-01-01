#!/bin/bash
#
# prepare running docker container for services
# runs each time container starts

if [ -r /etc/bareos/bareos.env ]; then
	#run local definition script
	source 		/etc/bareos/bareos.env
fi

if [ ! -f /etc/bareos/bareos-dir.conf ]
then
      
      	#initial config from build
        tar xfvz /etc.tgz
        
        #clean db
        rm -Rf /db/*
        
        #change names
      	NAME=$(grep -o -E "Name =(.*)-dir" /etc/bareos/bareos-dir.conf|perl -p -e 's/.*=\s*(\w+)-dir/\1/g;')
      	sed -i "s/$NAME/$HOSTNAME/" /etc/bareos/bareos-dir.conf
      	
				#translate name to ip for address config
				TARGET_HOST=$(getent hosts ${TARGET_HOST:-$HOSTNAME}|head -1|awk '{print $1}')
				TARGET_HOST=${TARGET_HOST:-$HOSTNAME}
      	sed -i "s/Address =.*/Address = ${TARGET_HOST}/" /etc/bareos/bareos-dir.conf      	
        
        #set db
        sed -i "s/dbpassword =.*/dbpassword = \"${BAREOS_DB_PASSWORD}\"/" /etc/bareos/bareos-dir.conf
        sed -i "s/dbdriver =.*/dbdriver = \"mysql\"/" /etc/bareos/bareos-dir.conf
        sed -i "s/dbuser =.*/dbuser = \"bareos\" \n  dbaddress = \"localhost\"\n  dbport = 3306/" /etc/bareos/bareos-dir.conf
				
				#set backup file location
			  sed -i "s/Archive Device.*$/Archive Device = \/backup/" /etc/bareos/bareos-sd.conf
				
				#change director name
				sed -i "s/localhost-dir/$HOSTNAME-dir/" /etc/bareos-webui/directors.ini
				
				#default configs
				#mv webgui
        for f in webui-consoles.conf webui-profiles.conf; do
        		if [ -e /etc/bareos/$f ]; then
        			mv /etc/bareos/$f /etc/bareos/bareos-dir.d/
        		fi
        done
				for d in bareos-dir.d bareos-clients.d; do
					d=/etc/bareos/$d
					if [ ! -d $d ]; then 
						mkdir -p $d
					fi
					echo "#dummy"> $d/dummy.conf
					if ! grep "$d" /etc/bareos/bareos-dir.conf >/dev/null; then 
        		echo "@|\"sh -c 'for f in $d/*.conf ; do echo @\${f} ; done'\""  >> /etc/bareos/bareos-dir.conf
        	fi
        done
        
        #sd
      	d=/etc/bareos/bareos-sd.d
      	echo "#dummy"> $d/dummy.conf
      	if ! grep "$d/\*\.conf" /etc/bareos/bareos-sd.conf >/dev/null; then 
      		echo "@|\"sh -c 'for f in $d/*.conf ; do echo @\${f} ; done'\""  >> /etc/bareos/bareos-sd.conf
      	fi  
        
fi

#init db and start db daemon
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-mysql}
if [ ! -d /db ] || ! ls -1 /db/* >/dev/null ; then
	service mysql stop
	chown -R mysql:adm /db /var/log/mysql
	sed -i "s#datadir=.*#datadir=/db#" /etc/mysql/my.cnf
	mysql_install_db --datadir=/db
	/usr/bin/mysqld_safe --datadir=/db &
	sleep 5
	mysqladmin -uroot  password "$DB_ROOT_PASSWORD"
else
	/usr/bin/mysqld_safe --datadir=/db &
	sleep 5
fi

#set passwordless db access			
if [ ! -f $HOME/.my.cnf ]; then
				echo "
[client]
host=localhost
user=root
password=${DB_ROOT_PASSWORD}
" >$HOME/.my.cnf
fi

#db check
if  mysql -e "show databases" | cut -d \| -f 1 | grep -w bareos >/dev/null; then
				echo "Database exists!"
else
				mysql <<EOS
GRANT USAGE ON *.* TO 'bareos'@'%' IDENTIFIED BY "${BAREOS_DB_PASSWORD}";
GRANT ALL PRIVILEGES ON bareos.* TO 'bareos'@'%';
FLUSH PRIVILEGES;
EOS
				#run bareos db scripts	
        /usr/lib/bareos/scripts/create_bareos_database
        /usr/lib/bareos/scripts/make_bareos_tables
        /usr/lib/bareos/scripts/grant_bareos_privileges
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') Start Daemons" >>/var/log/bareos/bareos.log
#fix permissions (again)
chown -R bareos:bareos /var/log/bareos /backup
chown -R www-data:www-data /var/log/apache2


#run services
service apache2 restart
service postfix restart
service bareos-dir restart
service bareos-sd restart
service bareos-fd restart

#exec final command (e.g. start.sh)
exec "$@"