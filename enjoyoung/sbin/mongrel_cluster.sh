#!/bin/bash
#***********************************************************
#This is a control script for mongrel cluster
#Usage: mongrel_cluster start|stop
#
#chkconfig:345 80 20
#description:Mongrel_Cluster
#
#Author: Jacky Xu ( Jacky.xu@serversupport.cn)
#
#Modify List: 
#		[2009-02-17] script finish
#		[2009-04-14] use sudo to make start
#		[2009-05-07] allow mongrel user to start and stop
#************************************************************

app='/usr/local/webservice/htdocs/enjoyoung/current'
conf='/usr/local/webservice/htdocs/enjoyoung/shared/config/mongrel_cluster.yml'
user='mongrel'

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

if [ ! -f "$conf" ]
then
	echo "Can not find mongrel_cluster.yml"
	exit 255
fi

user_id=`cat /etc/passwd | grep $user | cut -d ":" -f 3`

if [ $user_id -eq $UID ]
then
	mongrel_cluster_start="mongrel_rails cluster::start -C $conf"
	mongrel_cluster_stop="mongrel_rails cluster::stop -C $conf"
	mongrel_cluster_restart="mongrel_rails cluster::restart -C $conf"
elif [ $UID -eq 0 ]
then
	mongrel_cluster_start="sudo -u $user mongrel_rails cluster::start -C $conf"
	mongrel_cluster_stop="sudo -u $user mongrel_rails cluster::stop -C $conf"
	mongrel_cluster_restart="sudo -u $user mongrel_rails cluster::restart -C $conf"
else
	echo "You are not root or $user"
	exit 1
fi 



start() {
	$mongrel_cluster_start
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
	$mongrel_cluster_stop
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
	$mongrel_cluster_restart
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

