#!/bin/bash
#***********************************************************
#
#chkconfig:345 65 35
#description:Memcached
#
#Author: Jacky Xu ( Jacky.xu@serversupport.cn)
#
#Last modify: 2009-02-23
#************************************************************

MEMCACHED_HOME='/usr/local/webservice/memcached'
PORT='11211'
IP='127.0.0.1'
USER='mongrel'
MEM_SIZE='256'


start() {
	if [ ! -x "$MEMCACHED_HOME/bin/memcached" ]
	then
		echo "Can not execute $MEMCACHED_HOME/bin/memcached"
		exit 127
	fi
	MC_PID=`ps -ef | grep $MEMCACHED_HOME | grep -v grep | awk '{print $2}'`
	if [ ! -z $MC_PID ]
	then
		echo "Memcached had started, PID=$MC_PID"
		exit 99
	fi
	echo -n "Start Memcached ... "
	$MEMCACHED_HOME/bin/memcached -d -m $MEM_SIZE -l $IP -p $PORT -u $USER
	if [ `ps -ef | grep $MEMCACHED_HOME | grep -v grep -c` -eq 0 ]
	then
		echo "[Failed]"
		exit 127
	else
		echo "[OK]"
	fi
}

stop() {
	MC_PID=`ps -ef | grep $MEMCACHED_HOME | grep -v grep | awk '{print $2}'`
	if [ -z $MC_PID ]
	then
		echo "Memcached not start"
		exit 99
	fi
	echo -n "Stop Memcached PID=$MC_PID ... "
	kill -9 $MC_PID
	if [ $? -ne 0 ]
	then
		echo "[Failed]"
		exit 127
	else
		echo "[OK]"
	fi	
}

status() {
	ps -ef | grep $MEMCACHED_HOME | grep -v grep
}

reload() {
	stop
	sleep 3
	start
}

case "$1" in
    "start")
        start
        ;;

    "stop")
        stop
        ;;

    "status")
        status
        ;;

    "reload")
		reload
        ;;

    *)
        echo "Usage : `basename $0` { start | stop | status | reload }"
        exit 0
        ;;
esac
