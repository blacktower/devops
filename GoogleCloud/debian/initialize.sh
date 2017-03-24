#!/bin/bash
# Name:         initialize.sh
#
# Author:       Garrett Hunter - Blacktower, Inc.
# Date:         01-March-2017
# 
# Description:  Configure Debian linux to run WordPress
#               References: http://unix.stackexchange.com/questions/252671/installing-php7-0-from-sid-on-jessie
#               Package Inventory:
#                - Apache 2.4
#                - PHP 7.0 and various mods
#                - zip, unzip
#                - Google SQL Cloud Proxy
#                - WordPress
#
# Usage:        $ initialize.sh

TEMPDIR="/tmp"

#
# Update the distribution library to include required packages
#
function updateDistro {
	# Edit /etc/apt/sources.list to include PHP7 packages
	echo "deb http://packages.dotdeb.org jessie all" | tee --append /etc/apt/sources.list > /dev/null

	# Fetch the repository key and install it.
	wget https://www.dotdeb.org/dotdeb.gpg
	apt-key add dotdeb.gpg

	# Update global image
	apt-get update

    # Cleanup
    rm dotdeb.gpg
}

#
# Install base PHP, Apache, MySQL libraries
#
function installAMP {
	# Install the following packages:
	# - Apache2.4, PHP 7.0, PHP MySQL libraries
	apt-get install -y apache2 php7.0 php7.0-curl php7.0-gd php7.0-mbstring php7.0-mysql php7.0-xml php7.0-zip

	# Turn on mod_rewrite which is off by default
	# http://www.jarrodoberto.com/articles/2011/11/enabling-mod-rewrite-on-ubuntu
	# a2enmod is a script that enables the specified module within the apache2 configuration. It does this by creating symlinks within /etc/apache2/mods-enabled. Likewise, a2dismod disables a module by removing those symlinks.
	a2enmod rewrite

    # Restart apache to load the mysql modules for php
    service apache2 reload
}

#
# Install additional utilities
#
function installUtilities {
	# Install other utilities
	apt-get install -y zip unzip dos2unix
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
        sed s/INSTANCE_CONNECTION_NAME/"${SQLPROXY}"/ cloud_sql_proxy.default > cloud_sql_proxy.sh

        # Default run levels
        cp cloud_sql_proxy.sh /etc/init.d
        chmod +x /etc/init.d/cloud_sql_proxy.sh
        update-rc.d cloud_sql_proxy.sh defaults
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
updateDistro
installAMP
installUtilities
installSQLProxy
getWordPRess
echo "********* End Time:" $(date +"%Y-%m-%d %H:%M:%S")
