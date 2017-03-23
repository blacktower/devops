#!/bin/sh 
### BEGIN INIT INFO
# Provides:          cloud_sql_proxy
# Required-Start:    $local_fs $remote_fs $network $syslog $named
# Required-Stop:     $local_fs $remote_fs $network $syslog $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# X-Interactive:     false
# Short-Description: Google Cloud SQL Proxy
# Description:       Start the Google Cloud SQL Proxy process
### END INIT INFO
#
# Author:       Garrett Hunter
# Date:         03-March-2017
#

DESC="Google Cloud SQL Proxy"
CMD="cloud_sql_proxy"
DAEMON="/usr/sbin/${CMD}"

# Replace INSTANCE_ID with full proxy string
INSTANCE=INSTANCE_ID

start () {

  echo "Starting ${DESC}"
  nohup ${CMD} ${INSTANCE} > /dev/null 2>&1 &
  
}

stop () {

  echo "Stopping ${DESC}"
  killall ${CMD}

}

case "$1" in
  start)
    start 
  ;;  
  stop)
    stop 
  ;;  
  restart)
    stop 
    start 
  ;;  
  *)  
    echo "Usage: ${CMD} {start|stop|restart}"
    exit 1
    ;;  
esac

exit 0