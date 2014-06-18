#!/usr/bin/env bash

if [ -z "$1" ]; then
    php_version="distributed"
else
    php_version="$1"
fi

echo ">>> Installing PHP $1 version"

# if [ $php_version == "latest" ]; then
#     sudo add-apt-repository -y ppa:ondrej/php5
# fi

if [ $php_version == "previous" ]; then
    sudo add-apt-repository -y ppa:ondrej/php5-oldstable
fi

sudo apt-get update

# Install PHP
sudo apt-get install -y php5-cli php5-mysql php5-pgsql php5-sqlite php5-curl php5-gd php5-mcrypt php5-xdebug 

# xdebug Config
cat > $(find /etc/php5 -name xdebug.ini) << EOF
zend_extension=$(find /usr/lib/php5 -name xdebug.so)
xdebug.remote_enable = 1
xdebug.remote_connect_back = 1
xdebug.remote_port = 9000
xdebug.scream=1
xdebug.cli_color=1
xdebug.show_local_vars=1
xdebug.max_nesting_level=1000

; var_dump display
xdebug.var_display_max_depth = 5
xdebug.var_display_max_children = 256
xdebug.var_display_max_data = 1024
EOF

sed -i "s/memory_limit = .*/memory_limit = 256M/" /etc/php5/apache2/php.ini

# PHP Error Reporting Config
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/apache2/php.ini
sed -i "s/html_errors = .*/html_errors = On/" /etc/php5/apache2/php.ini

# PHP Date Timezone
sed -i "s/;date.timezone =.*/date.timezone = ${2/\//\\/}/" /etc/php5/apache2/php.ini
sed -i "s/;date.timezone =.*/date.timezone = ${2/\//\\/}/" /etc/php5/cli/php.ini

# Make sure php5-apache2 is running as a Unix socket on "distributed" version
# if [ $php_version == "distributed" ]; then
#     sed -i "s/listen = .*/listen = \/var\/run\/php5-apache2.sock/" /etc/php5/apache2/pool.d/www.conf
# fi

# sudo service apache2 restart
