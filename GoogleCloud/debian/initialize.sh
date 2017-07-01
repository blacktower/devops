#!/bin/bash
# ----------------------------------------------------------------------
# Name:         initialize.sh
# Author:       Garrett Hunter - Blacktower, Inc.
# Date:         01-March-2017
# 
# Configure a Debian 8 (Jessie) VM to run WordPress
# References: http://unix.stackexchange.com/questions/252671/installing-php7-0-from-sid-on-jessie
# Package Inventory:
# - Apache 2.4
# - PHP 7.0 and various mods
# - zip, unzip
# - Google SQL Cloud Proxy
# - WordPress
#
# Usage:        $ initialize.sh
# ----------------------------------------------------------------------

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
	# Edit /etc/apt/sources.list to include PHP7 packages (https://deb.sury.org/)
    apt-get install -y apt-transport-https lsb-release ca-certificates
    wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

	# Update global image
	apt-get update -y
}

# ######################################################################
# Install base Apache, MySQL, and PHP packages
# ######################################################################
function installAMP {

	apt-get install -y apache2 modsecurity-crs memcached php php-curl php-gd php-mbstring php-mysql php-xml php-zip php-memcached mysql-client

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
function installSQLProxy {
    if [ -d ${TEMPDIR} ]; then

        cd ${TEMPDIR} || return

        # Download and Install the Google SQL Proxy
        wget -O cloud_sql_proxy https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64

        # Make the proxy executable and move to system bin
        chmod +x cloud_sql_proxy
        mv cloud_sql_proxy /usr/sbin
        
        #
        # Add proxy to init states
        # - Downlaod the init script and update proxy connection string with meta set in compute engine instance
        # - Add init script to default run levels
        curl -s https://raw.githubusercontent.com/blacktower/devops/master/GoogleCloud/debian/etc/init.d/cloud_sql_proxy.default > cloud_sql_proxy.default
        SQLPROXY=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/sqlproxy -H "Metadata-Flavor: Google")
        sed s/INSTANCE_CONNECTION_NAME/"${SQLPROXY}"/ cloud_sql_proxy.default > cloud_sql_proxy

        # Default run levels
        cp cloud_sql_proxy /etc/init.d
        chmod +x /etc/init.d/cloud_sql_proxy
        update-rc.d cloud_sql_proxy defaults
        service cloud_sql_proxy start

        # Cleanup
        rm -rf cloud_sql_proxy cloud_sql_proxy.default cloud_sql_proxy.sh
    else
        echo "Missing ${TEMPDIR} directory."
    fi
}

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
installSQLProxy
# This does not seem to be helpful
getWordPRess
echo "********* End Time:" $(date +"%Y-%m-%d %H:%M:%S")
