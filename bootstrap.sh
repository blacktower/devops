#!/bin/sh
#
# Usage: install.sh -o [debian|ubuntu] -p [google|aws]
#

# Currently supported OSs and Providers
# OSS: debian, ubuntu
# PROVIDERS: google, aws

OS='ubuntu'
PROVIDER=''

cd /tmp || exit

wget https://raw.githubusercontent.com/blacktower/devops/master/install.sh

chmod +x install.sh
./install.sh -p ${PROVIDER} > install.log