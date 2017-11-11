#!/bin/bash
# Name:         installwp.sh
#
# Author:       Garrett Hunter - Blacktower, Inc.
# Date:         10-Nov-2017
# 
# Description:  Install WordPress latest version
#
#               ** Must be run as root **
#
# -------------------------------------------------------------------------------

TEMPDIR="/tmp"

function getWordPress {
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

getWordPress
