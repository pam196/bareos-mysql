#!/bin/bash
#
#do some configuration tasks here to keep Dockerfile short
 
#apache redirect root
echo "
ServerName localhost
<Location />
	RedirectMatch 301 ^/$ /bareos-webui/
</Location>
" >/etc/apache2/conf-available/bareos-redirect.conf
ln -s /etc/apache2/conf-available/bareos-redirect.conf /etc/apache2/conf-enabled/bareos-redirect.conf

#fix permissions
chown -R bareos:bareos /var/log/bareos /backup /etc/bareos
chown -R www-data:www-data /var/log/apache2
chown -R mysql:adm /db /var/log/mysql

#enable services
for s in bareos-dir bareos-sd bareos-fd postfix apache2 mysql; do
	update-rc.d $s defaults &&  update-rc.d $s enable
done
