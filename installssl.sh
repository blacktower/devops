#!/bin/bash
# ----------------------------------------------------------------------
# Name:         installssl.sh
# Author:       Garrett Hunter - Blacktower, Inc.
# Date:         10-November-2017
# 
# Install a Let's Encrypt SSL cert to Apache. Must be run via sudo and expects the 
# certbot package to be installs
#
#               ** Must be run as root **
#
# References: https://certbot.eff.org
#
# Usage:        $ installssl.sh <domain>
# ----------------------------------------------------------------------

certbot --apache -d ${DOMAIN} -n
