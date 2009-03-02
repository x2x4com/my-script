#!/bin/bash
#***********************************************************
#
#This is a control script for nginx
#Usage: nginx.sh start|stop|reload|status
#
#chkconfig:345 85 15
#description:Nginx
#
#Author: Jacky Xu ( Jacky.xu@serversupport.cn)
#
#Last modify: 2009-02-17
#************************************************************


NGINX_HOME='/usr/local/webservice/nginx'
ERROR_EXT='99'


start() {
	${NGINX_HOME}/sbin/nginx # >/dev/null 2>&1
	stats=$?
	echo -n "Start Nginx ...."
	if [ $stats -ne 0 ];then
		echo " [Failed]"
		exit ${ERROR_EXT}
	else
		echo " [OK]"
		exit 0
	fi
}

stop() {
	kill -15 `ps -ef | grep 'nginx:' | grep -v grep | grep master | awk '{print $2}'` >/dev/null 2>&1 
	stats=$?
	echo -n "Stop Nginx ...."
    if [ $stats -ne 0 ];then
        echo " [Failed]"
        exit ${ERROR_EXT}
    else
        echo " [OK]"
        exit 0
    fi
}

status() {
	echo "Process of Nginx"
	ps -ef | grep 'nginx:' | grep -v grep
	exit 0
}

reload() {
#	time_now=`date +%H:%M`
#	declare -a wt
#	wt=(`ps -ef | grep 'nginx:' | grep -v grep | grep worker | awk '{print $5}'`)
#	count=0
#	tmp_t=${wt[0]}
#	echo -n "Reload Nginx ...."
#	while [ "$time_now" == "$tmp_t" ]
#	do
#		echo -n "."
#		let count=$count+1
#		sleep 1
#		tmp_t=`date +%H:%M`
#	done
#    kill -HUP `ps -ef | grep 'nginx:' | grep -v grep | grep master | awk '{print $2}'`  >/dev/null 2>&1
#	stats=$?
#   if [ $stats -ne 0 ];then
#        echo " [Failed]"
#        exit ${ERROR_EXT}
#    else
#		sleep 2
#		declare -a nwt
#		nwt=(`ps -ef | grep 'nginx:' | grep -v grep | grep worker | awk '{print $5}'`)
#       if [ "${wt[0]}" != "${nwt[0]}" ];then
#			echo " [OK]"
#        	exit 0
#		else
#	        echo " [Failed]"
#			$NGINX_HOME/sbin/nginx -t
#        	exit ${ERROR_EXT}
#		fi
#    fi
	$NGINX_HOME/sbin/nginx -t
	echo -n "Check Nginx Configure ...."
	if [ $? -ne 0 ];then
        echo " [Failed]"
        exit ${ERROR_EXT}
    else
    	echo " [OK]"
	fi
	echo -n "Reload Nginx ...."
	kill -HUP `ps -ef | grep 'nginx:' | grep -v grep | grep master | awk '{print $2}'`  >/dev/null 2>&1
	if [ $? -ne 0 ];then
        echo " [Failed]"
        exit ${ERROR_EXT}
    else
    	echo " [OK]"
	fi
	
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
