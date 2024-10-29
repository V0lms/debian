#! /bin/bash
####Installs
apt -y install mariadb-server
apt -y install apache2 libapache2-mod-php php php-mysql ufw
apt -y install apache2-utils

clear

####Base
#BBDD
echo "== BBDD =="
echo "Nombre de usuario:"
read usuario
echo "Contraseña (misma root):"
read contrasenya

touch user.sql
mysql -u root -p >> user.sql -e"CREATE DATABASE newdb;CREATE USER $usuario@'localhost' IDENTIFIED BY $contrasenya; GRANT ALL PRIVILEGES ON newdb.* to $usuario@'localhost'; FLUSH PRIVILEGES; quit"


#Pagina web
ufw enable
ufw allow "WWW Full"
ufw status

echo "Nombre de la web (sin el .com):"
read pagina

if [ -d /var/www/$pagina ]; then
    echo "Ya existe esa pagina"
    exit 1
fi
mkdir  /var/www/$pagina

chown -R www-data:www-data /var/www/$pagina

echo  $(ip a | grep inet | grep /24 | grep -oP '(?<=inet ).*?(?=/24)')
echo "Pega lo de arriba"
read laip

echo "$laip   $pagina.com" >> /etc/hosts
systemctl restart apache2



####Virtualhosting
echo "Terminado lo basico"
echo "Empezando Virtualhosting"
sleep 3
clear

touch /var/www/$pagina/index.html
echo "<h1>FURULAAAAA</h1>
        <p>Pagiana web alojada en <strong>$pagina.com</strong></p>
        <footer>Gracias Victor</footer>" >> /var/www/$pagina/index.html

touch /etc/apache2/sites-available/$pagina.conf
echo "<VirtualHost *:80>
    ServerName $pagina.com
    ServerAdmin webmaster@$pagina.com
    DocumentRoot /var/www/$pagina

#FJmagas puso esto que me da error, descomentarlo si quereis
#     <Directory /var/www/$pagina>
#         Options Indexes FollowSymLink
#         AllowOverride None
#         Require all granted
#     </Directory>

</VirtualHost>" >> /etc/apache2/sites-available/$pagina.conf

#Descativar el default
a2dissite 000-default.conf
a2ensite $pagina.conf

systemctl reload apache2


#SSL
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt

rm /etc/apache2/sites-available/default-ssl.conf
touch /etc/apache2/sites-available/default-ssl.conf
echo "<VirtualHost *:443>
    ServerName $pagina.com
    ServerAdmin webmaster@$pagina.com
    DocumentRoot /var/www/$pagina

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key
</VirtualHost>" >> /etc/apache2/sites-available/default-ssl.conf

a2ensite default-ssl.conf
a2enmod ssl


#HTTP a HTTPS
rm /etc/apache2/sites-available/$pagina.conf
touch /etc/apache2/sites-available/$pagina.conf
echo "<VirtualHost *:80>
    ServerName $pagina.com
    ServerAdmin webmaster@$pagina.com
    DocumentRoot /var/www/$pagina

#FJmagas puso esto que me da error, descomentarlo si quereis
#     <Directory /var/www/$pagina>
#         Options Indexes FollowSymLink
#         AllowOverride None
#         Require all granted
#     </Directory>

# Redirige al puerto 443 (HTTPS)
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>" >> /etc/apache2/sites-available/$pagina.conf


a2enmod rewrite
systemctl restart apache2



####Webdav
echo "Terminado Virtualhosting"
echo "Empezando WebDav"
sleep 3
clear

mkdir /var/www/webdav
echo "porfavor funciona" >> /var/www/webdav/prueba.txt
chown -R www-data:www-data /var/www/webdav
chmod -R 755 /var/www/webdav

touch /etc/apache2/sites-available/webdav.conf
echo "
<VirtualHost *:8181>
    ServerAdmin webmaster@$pagina.com
    DocumentRoot /var/www/webdav
    ServerName www.$pagina.com
    Alias /webdav /var/www/webdav

    <Directory /var/www/webdav>
        Dav On
        AuthType Basic
        AuthName 'webdav'
        AuthUserFile /etc/apache2/.htpasswd
        Require valid-user
    </Directory>
</VirtualHost>" >> /etc/apache2/sites-available/webdav.conf

a2ensite webdav
ufw allow 8181/tcp
ufw status

echo "== WebDav =="
echo "Nombre de usuario (minusculas):"
read usuario
echo "*** Pon una contraseña distinta a root ***"
htpasswd -c /etc/apache2/.htpasswd $usuario

a2enmod dav_fs
a2enmod dav_lock

apache2ctl –M
sleep 1

echo "Listen 8181" >> /etc/apache2/ports.conf

####FINAL
clear
service apache2 restart
echo "TERMINADO"
echo "   Pagina normal en:"
echo "   http://$pagina.com"
echo ""
echo "   Pagina webdav en:"
echo "   http://$laip/webdav"
echo "   http://$pagina/webdav.com"


sleep 10
systemctl status apache2.service >> file.txt
vi file.txt

