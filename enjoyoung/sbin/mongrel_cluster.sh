#!/bin/bash
#***********************************************************
#
#This is a control script for mongrel cluster
#Usage: nginx.sh start|stop
#
#chkconfig:345 80 20
#description:Mongrel_Cluster
#
#Author: Jacky Xu ( Jacky.xu@serversupport.cn)
#
#Last modify: 2009-03-03
#************************************************************

app='/home/jacky/tmp/aaaaa'
user='jacky'

if [ ! -d $app ]
then
	echo "$app is not a dir"
	exit 255
fi

if [ `grep -c ${user} /etc/passwd` -eq 0 ]
then
	echo "Can not find $user"
	exit 255
fi

cd $app

if [ ! -f "config/mongrel_cluster.yml" ]
then
	echo "Can not find mongrel_cluster.yml"
	exit 255
fi

start() {
	mongrel_rails cluster::start
	stats=$?
	echo -n "Start Mongrel Cluster ...."
	if [ $stats -ne 0 ];then
		echo " [Failed]"
		exit ${ERROR_EXT}
	else
		echo " [OK]"
		exit 0
	fi
}

stop() {
	mongrel_rails cluster::stop
	stats=$?
	echo -n "Stop Mongrel Cluster ...."
	if [ $stats -ne 0 ];then
		echo " [Failed]"
		exit ${ERROR_EXT}
	else
		echo " [OK]"
		exit 0
	fi
}

restart() {
	mongrel_rails cluster::restart
	stats=$?
	echo -n "Restart Mongrel Cluster ...."
	if [ $stats -ne 0 ];then
		echo " [Failed]"
		exit ${ERROR_EXT}
	else
		echo " [OK]"
		exit 0
	fi
}


case "$1" in
    "start")
        start
        ;;

    "stop")
        stop
        ;;

    "restart")
        restart
        ;;

    *)
        echo "Usage : `basename $0` { start | stop }"
        exit 0
        ;;
esac
