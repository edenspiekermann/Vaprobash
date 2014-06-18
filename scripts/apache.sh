#!/usr/bin/env bash

# Test if PHP is installed
php -v > /dev/null 2>&1
PHP_IS_INSTALLED=$?

echo ">>> Installing Apache Server"

[[ -z "$1" ]] && { echo "!!! IP address not set. Check the Vagrant file."; exit 1; }

if [ -z "$2" ]; then
	public_folder="/vagrant"
else
	public_folder="$2"
fi

# Add repo for latest FULL stable Apache
# (Required to remove conflicts with PHP PPA due to partial Apache upgrade within it)
# sudo add-apt-repository -y ppa:ondrej/apache2

# Update Again
sudo apt-get update

# Install Apache
# sudo apt-get install -y apache2-mpm-event libapache2-mod-fastcgi
sudo apt-get install -y apache2 

echo ">>> Configuring Apache"

# Apache Config
sudo a2enmod rewrite actions ssl
curl -L https://gist.githubusercontent.com/fideloper/2710970/raw/vhost.sh > vhost
sudo chmod guo+x vhost
sudo mv vhost /usr/local/bin

a2dissite 000-default

# Create a virtualhost to start, with SSL certificate
sudo vhost -s $1.xip.io -d $public_folder -p /etc/ssl/xip.io -c xip.io

sudo sed -i "s/Require all granted/# Require all granted/" /etc/apache2/sites-enabled/$1.xip.io.conf

if [[ $PHP_IS_INSTALLED ]]; then
  sudo apt-get install -y libapache2-mod-php5

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
fi

sudo service apache2 restart
