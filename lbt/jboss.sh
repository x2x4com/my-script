#!/bin/sh

JAVA_HOME=/usr/local/java
PATH=$PATH:$JAVA_HOME/bin:$JAVA_HOME/jre/bin
CLASSPATH=$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
LANG=zh_CN.GB18030
jboss_home=/usr/local/jboss
jboss_log=/var/log/jboss_tty_out.log



case "$1" in
    "start")
    echo "Start Jboss..."
	/usr/bin/sudo -u jboss $jboss_home/jboss/bin/run.sh 2&>1 >> jboss_log=/var/log/jboss_tty_out.log &
        ;;

    "stop")
        echo "Stop Jboss..."
	for i in `ps -ef | grep jboss | grep java | grep -v grep | awk '{print $2}'`
	do
	kill -9 $i
	done
        ;;

    *)
        echo "Usage : `basename $0` {start | stop}"
        exit 0
        ;;
esac

