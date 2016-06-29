#! /usr/bin/env bash

# Variables
APPENV=local
DBHOST=localhost
DBPASSWD=rootformysqlvagrantprovisioning

echo -e "\n--- Updating packages list ---\n"
apt-get -qq update

echo -e "\n--- Install base packages ---\n"
apt-get -y install emacs curl git

echo -e "\n--- Add some repos to update our distro ---\n"
add-apt-repository ppa:ondrej/php5
#add-apt-repository ppa:chris-lea/node.js > /dev/null 2>&1

echo -e "\n--- Updating packages list ---\n"
apt-get -qq update

echo -e "\n--- Install MySQL specific packages and settings ---\n"
echo "mysql-server mysql-server/root_password password $DBPASSWD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $DBPASSWD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | debconf-set-selections
apt-get -y install mysql-server-5.5 phpmyadmin

echo -e "\n--- Secure MySQL ---\n"
# then secure mysql (this replicates the effects of mysql_secure_installation without needing interaction)
# Make sure that NOBODY can access the server without a password
mysql -e "UPDATE mysql.user SET Password = PASSWORD('$DBPASSWD') WHERE User = 'root'"
# Kill the anonymous users
mysql -e "DROP USER ''@'localhost'"
# Because our hostname varies we'll use some Bash magic here.
mysql -e "DROP USER ''@'$(hostname)'"
# Kill off the demo database
mysql -e "DROP DATABASE test"
# Make our changes take effect
mysql -e "FLUSH PRIVILEGES"
# Any subsequent tries to run queries this way will get access denied because lack of usr/pwd param

#echo -e "\n--- Setting up our MySQL user and db ---\n"
#mysql -uroot -p$DBPASSWD -e "CREATE DATABASE $DBNAME"
#mysql -uroot -p$DBPASSWD -e "grant all privileges on $DBNAME.* to '$DBUSER'@'localhost' identified by '$DBPASSWD'"

echo -e "\n--- Installing PHP-specific packages ---\n"
apt-get -y install php5 apache2 libapache2-mod-php5 php5-curl php5-gd php5-mcrypt php5-mysql php-apc

echo -e "\n--- Enabling mod-rewrite ---\n"
a2enmod rewrite

echo -e "\n--- Allowing Apache override to all ---\n"
sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf

echo -e "\n--- Setting document root to public directory ---\n"
if ! [ -L /var/www ]; then
    rm -rf /var/www
    ln -fs /vagrant_shared /var/www
    # put a couple of test files in place
    echo "<html><head><title>hello world</title></head><body><h2>hello world</h2>things are working, at least up to this point</body></html>" > /vagrant_shared/hello_world.html
    echo "<html><head><title>hello php</title></head><body><h2>hello php</h2>if working, should see something here: <?php echo 'hello php';?></body></html>" > /vagrant_shared/hello_php.php
fi

echo -e "\n--- See the PHP errors ---\n"
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/apache2/php.ini

echo -e "\n--- Configure Apache to use phpmyadmin ---\n"
echo -e "\n\nListen 81\n" >> /etc/apache2/ports.conf
cat > /etc/apache2/conf-available/phpmyadmin.conf << "EOF"
<VirtualHost *:81>
    ServerAdmin webmaster@localhost
    DocumentRoot /usr/share/phpmyadmin
    DirectoryIndex index.php
    ErrorLog ${APACHE_LOG_DIR}/phpmyadmin-error.log
    CustomLog ${APACHE_LOG_DIR}/phpmyadmin-access.log combined
</VirtualHost>
EOF
a2enconf phpmyadmin

echo -e "\n--- Add environment variables to Apache ---\n"
cat > /etc/apache2/sites-enabled/000-default.conf <<EOF
<VirtualHost *:80>
    DocumentRoot /var/www
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    SetEnv APP_ENV $APPENV
    SetEnv DB_HOST $DBHOST
    SetEnv DB_PASS $DBPASSWD
</VirtualHost>
EOF

echo -e "\n--- Restarting Apache ---\n"
service apache2 restart

#echo -e "\n--- Installing Composer for PHP package management ---\n"
#curl --silent https://getcomposer.org/installer | php > /dev/null 2>&1
#mv composer.phar /usr/local/bin/composer

#echo -e "\n--- Installing NodeJS and NPM ---\n"
#apt-get -y install nodejs > /dev/null 2>&1
#curl --silent https://npmjs.org/install.sh | sh > /dev/null 2>&1

#echo -e "\n--- Installing javascript components ---\n"
#npm install -g gulp bower > /dev/null 2>&1

#echo -e "\n--- Updating project components and pulling latest versions ---\n"
#cd /vagrant
#sudo -u vagrant -H sh -c "composer install" > /dev/null 2>&1
#cd /vagrant/client
#sudo -u vagrant -H sh -c "npm install" > /dev/null 2>&1
#sudo -u vagrant -H sh -c "bower install -s" > /dev/null 2>&1
#sudo -u vagrant -H sh -c "gulp" > /dev/null 2>&1
