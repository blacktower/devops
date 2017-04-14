#!/bin/bash
# Name:         installwp.sh
#
# Author:       Garrett Hunter - Blacktower, Inc.
# Date:         23-March-2017
# 
# Description:  Download and configure WordPress in default debian directory
#               References: http://unix.stackexchange.com/questions/252671/installing-php7-0-from-sid-on-jessie
#               Package Inventory:
#                - Apache 2.4
#                - PHP 7.0 and various mods
#                - zip, unzip
#                - Google SQL Cloud Proxy
#                - WordPress
#
# Usage:        $ installwp.sh

# Download Latest WordPress archive from WP org
wget https://wordpress.org/latest.tar.gz

#Extract the archive showing the progress
tar xvf latest.tar.gz 

#Copy the content of WP Salts page
WPSalts=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

#generate a random string; lower and upper case letters + numbers; maximun 9 characters
TablePrefx=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 9 | head -n 1)_

#Copy the current directory user name
WWUSER=$(stat -c '%U' ./)

#Add the following PHP code inside wp-config
cat <<EOF > wordpress/wp-config-sample.php
<?php
/***Managed by Kaiten Support - Leonardo Gandini***/

define('DB_NAME', '');
define('DB_USER', '');
define('DB_PASSWORD', '');
define('DB_HOST', 'localhost');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

/*WP Tweaks*/
#define( 'WP_SITEURL', '' );
#define( 'WP_HOME', '' );
#define( 'ALTERNATE_WP_CRON', true );
#define('DISABLE_WP_CRON', 'true');
#define('WP_CRON_LOCK_TIMEOUT', 900);
#define('AUTOSAVE_INTERVAL', 300);
#define( 'WP_MEMORY_LIMIT', '256M' );
#define( 'FS_CHMOD_DIR', ( 0755 & ~ umask() ) );
#define( 'FS_CHMOD_FILE', ( 0644 & ~ umask() ) );
#define( 'WP_ALLOW_REPAIR', true );
#define( 'FORCE_SSL_ADMIN', true );
#define( 'AUTOMATIC_UPDATER_DISABLED', true );
#define( 'WP_AUTO_UPDATE_CORE', false );

$WPSalts

\$table_prefix = '$TablePrefx';

define('WP_DEBUG', false);

if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

require_once(ABSPATH . 'wp-settings.php');
EOF

#Now that we are good, let's rename the wp-config sample
mv wordpress/wp-config-sample.php wordpress/wp-config.php

#Move wordpress folder content in the current directory and remove the leftovers
mv ./wordpress/* ./ && rm -rf latest.tar.gz && rm -rf ./wordpress

#Apply the definer user name to all the new freshly created wordpress files, plus the group (here the main on for Plesk Virtual Hosts)
chown -R $WWUSER:psacln ./*

#Just to be sure, let's fix files and directories permissions
find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;

#Fancy message with colored background
echo "$(tput setaf 7)$(tput setab 6)---|-WP READY TO ROCK-|---$(tput sgr 0)"