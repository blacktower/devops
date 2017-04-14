#!/bin/bash
# Name:         initialize.sh
#
# Author:       Garrett Hunter - Blacktower, Inc.
# Date:         14-April-2017
# 
# Description:  Configure CentOS linux to run WordPress
#               References: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/install-LAMP.html
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
# Update the distribution library to include required packages
#
function updateDistro {
	# Update global image
	yum update -y

    # Cleanup
}

#
# Install base PHP, Apache, MySQL libraries
#
function installAMP {
	# Install the following packages:
	# - Apache2.4, PHP 7.0, PHP MySQL libraries
	sudo yum install -y httpd24 php70 php70-mysqld php70-gd php70-mbstring php70-zip mysql56

	# Enable httpd network access and read / write access
    # http://stackoverflow.com/questions/4078205/php-cant-connect-to-mysql-with-error-13-but-command-line-can
    # http://stackoverflow.com/questions/32044160/google-cloud-sql-with-php
    sudo setsebool -P httpd_can_network_connect=1
    sudo chcon -t httpd_sys_rw_content_t html

    # Add Apache to system start and start Apache
    sudo chkconfig httpd on
    sudo service httpd start
}

#
# Install additional utilities
#
function installUtilities {
	# Install other utilities
	sudo yum install -y zip unzip dos2unix
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
updateDistro
installAMP
installUtilities
installSQLProxy
# This does not seem to be helpful
# getWordPRess
echo "!!!!!!! REMBER TO FIX AllowOverride !!!!!!!! "
echo "********* End Time:" $(date +"%Y-%m-%d %H:%M:%S")
