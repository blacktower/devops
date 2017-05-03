#!/bin/bash
# Name:         initialize.sh
#
# Author:       Garrett Hunter - Blacktower, Inc.
# Date:         02-May-2017
# 
# Description:  Configure Ubuntu linux to run WordPress
#               References: 
#               ** Must be run as root **
#               Package Inventory:
#                - Apache 2.4
#                - PHP 7.0 and various mods
#                - zip, unzip
#                - WordPress
#
# Usage:        $ initialize.sh

TEMPDIR="/tmp"

#
# Install packages I may want to have before we get started
#
function installPrereqs {
	apt-get install -y zip unzip dos2unix
}

#
# Update the distribution library to include required packages
#
function updateDistro {
	# Update global image
	apt-get update -y
}

# ######################################################################
# Install base Apache, MySQL, and PHP packages
# ######################################################################
function installAMP {

	apt-get install -y apache2 memcached php7.0 php7.0-curl php7.0-gd php7.0-mbstring php7.0-mysql php7.0-xml php7.0-zip php-memcached libapache2-mod-php7.0 mysql-client-5.7

    # Overwrite the apache2.conf file with our preconfigurations
    wget -O /etc/apache2/apache2.conf https://raw.githubusercontent.com/blacktower/devops/master/Apache/apache2.conf

    # Load and enable our custom optimized conf file
	# a2enconf is a script that enables the specified configuration within the apache2 configuration. 
    # It does this by creating symlinks within /etc/apache2/conf-enabled. Likewise, a2disconf disables a configuration by removing those symlinks.
    wget -O /etc/apache2/conf-available/optimized.conf https://raw.githubusercontent.com/blacktower/devops/master/Apache/optimized.conf
    a2enconf optimized

	# Turn on modules which are off by default
	# a2enmod is a script that enables the specified module within the apache2 configuration. 
    # It does this by creating symlinks within /etc/apache2/mods-enabled. Likewise, a2dismod disables a module by removing those symlinks.
	a2enmod expires headers include rewrite
    a2dismod -f autoindex

    # ---------------------------------------------------
    # | Install Google's mod_pagespeed for Apache
    # | https://www.howtoforge.com/tutorial/speed-up-apache-with-mod_pagespeed-and-memcached-on-debian-8-jessie/
    # ---------------------------------------------------
    cd /tmp
    wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb 
    dpkg -i mod-pagespeed-stable_current_amd64.deb

    # Configure Pagespeed to use memcache
    sed -ie 's/# ModPagespeedMemcachedServers/ModPagespeedMemcachedServers/' /etc/apache2/mods-available/pagespeed.conf

    # Restart apache to load the mysql modules for php
    service apache2 reload
}

#
# Install any connectors and integrations
#
#function installSQLProxy {

  # Nothing to do for centos at this time
  
#}

function getWordPRess {
    if [ -d ${TEMPDIR} ]; then

        cd ${TEMPDIR} || return

        #
        # Download latest WordPress and deploy
        wget https://wordpress.org/latest.tar.gz
        tar xvf latest.tar.gz
        cp -R wordpress/* /var/www/html

        #
        # Set file permissions for web sever to work with Wordpress
        chmod 775 /var/www/html
        chown -R www-data:www-data /var/www/html
        find /var/www/html -type d -exec chmod 2775 {} \;
        find /var/www/html -type f -exec chmod 0664 {} \;

        #
        # Clean up
        rm /var/www/html/index.html /var/www/html/readme.html /var/www/html/license.txt
        rm -rf wordpress latest.tar.gz
    else
        echo "Missing ${TEMPDIR} directory."
    fi
}

echo "********* Start Time:" $(date +"%Y-%m-%d %H:%M:%S")
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi
installPrereqs
updateDistro
installAMP
# This does not seem to be helpful
getWordPRess
echo "********* End Time:" $(date +"%Y-%m-%d %H:%M:%S")
