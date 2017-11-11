#!/bin/bash
# Name:         install.sh
#
# Author:       Garrett Hunter - Blacktower, Inc.
# Date:         08-Nov-2017
# 
# Description:  Configure a linux instance with Apache 2.4 / PHP 7.0. / MySQL client / Certbot (Let's Encrypt)
#               Supports Debian 9 on Google Cloud and Ubuntu 16 (Xeniel) on AWS
#
#               ** Must be run as root **
#
# -------------------------------------------------------------------------------

# Currently supported OSs and Providers
OSS=(debian ubuntu)
PROVIDERS=(google aws)

usage() { printf "Usage: $0 -o [debian|ubuntu] -p [google|aws]\n" 1>&2; exit 1; }

# Check options and quit if incorrect
while getopts ":o:p:" opt; do
  case "${opt}" in
    o)
      for i in "${OSS[@]}"; do
        if [[ ${OPTARG} == ${i} ]]; then
          OS=${OPTARG}
        fi
      done
    ;;
    p)
      for i in "${PROVIDERS[@]}"; do
        if [[ ${OPTARG} == ${i} ]]; then
          PROVIDER=${OPTARG}
        fi
      done
    ;;
  esac
done

if [ -z "${OS}" ] || [ -z "${PROVIDER}" ]; then
    usage
    exit 1
fi

# Inputs passed so let's proceed
TEMPDIR="/tmp"

#
# Install packages I may want to have before we get started
#
function installPrereqs {
	MODS="zip unzip dos2unix"
    
    case "${PROVIDER}" in
        aws)
            MODS="${MODS} awscli"
        ;;
    esac

	apt install -y ${MODS}
}

#
# Update the distribution library to include required packages
#
function updateDistro {
    case "${OS}" in
        debian|ubuntu)
            # Update global image
	        apt update -y
        ;;
    esac
}

# ######################################################################
# Install base Apache, MySQL, and PHP packages
#  - Includes specific optimizations
# ######################################################################
function installAMP {
    MODS="memcached"
    APACHEMODS="apache2";
    PHPMODS="php7.0 php7.0-curl php7.0-gd php7.0-mbstring php7.0-mysql php7.0-xml php7.0-zip php-memcached"
    MYSQLMODS="mysql-client"

    case "${OS}" in
        debian|ubuntu)
            MODS="${MODS} ${APACHEMODS} ${PHPMODS} ${MYSQLMODS}"
        ;;
    esac
	apt install -y ${MODS}

    # Overwrite the apache2.conf file with our preconfigurations
    wget -O /etc/apache2/apache2.conf https://raw.githubusercontent.com/blacktower/devops/master/Apache/apache2.conf

    # Load and enable additional optimized conf files
	# a2enconf is a script that enables the specified configuration within the apache2 configuration. 
    # It does this by creating symlinks within /etc/apache2/conf-enabled. Likewise, a2disconf disables a configuration by removing those symlinks.
    wget -O /etc/apache2/conf-available/optimized.conf https://raw.githubusercontent.com/blacktower/devops/master/Apache/optimized.conf
    wget -O /etc/apache2/conf-available/security.conf https://raw.githubusercontent.com/blacktower/devops/master/Apache/security.conf
    a2enconf optimized security

	# Enable/disable modules which are off/on by default
	# a2enmod/a2dismod are scripts that enable/disable the specified modules within the apache2 configuration. 
    # They do this by creating/removing symlinks within /etc/apache2/mods-enabled.
	a2enmod expires headers include rewrite
    a2dismod -f autoindex status

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

# ######################################################################
# Install Certbot for LetsEncrypt SSL
# ######################################################################
function installCertbot {

    case "${OS}" in
        ubuntu)
            apt install -y software-properties-common
            add-apt-repository -y ppa:certbot/certbot
            apt update
        ;;
    esac    
    apt install -y python-certbot-apache  
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
        curl -s https://raw.githubusercontent.com/blacktower/devops/master/GoogleCloud/etc/init.d/cloud_sql_proxy.default > cloud_sql_proxy.default
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

echo "********* Start Time:" $(date +"%Y-%m-%d %H:%M:%S")
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi
updateDistro
installPrereqs
installAMP
installCertbot

case "${PROVIDER}" in
    google)
        installSQLProxy
    ;;
esac
echo "********* End Time:" $(date +"%Y-%m-%d %H:%M:%S")