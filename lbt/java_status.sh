#!/bin/sh
# New fix @ 2008-12-19
# Jacky Xu
#

jboss_log_root='/usr/local/jboss/jboss/server/default/log'
jboss_log_name='server.log'
stats_log='/root/jboss_status.log'
sysdate=`date +%Y%m%d%H%M%S`
logdate='date +[%y-%m-%d_%H:%M:%S]'
lock='/root/jboss_status.lock'

if [ -f $lock ]
then
	echo `$logdate` >> $stats_log
	exit 1
fi

touch $lock

pc1=0
pc2=0
pc3=0
pc4=0

for i in `netstat -antp | grep java | awk '{print $4}'| cut -d ":" -f 4`
do
if [ $i = 65532 ]; then
pc1=1
elif [ $i = 65533 ]; then
pc2=1
elif [ $i = 65534 ]; then
pc3=1
elif [ $i = 65535 ]; then
pc4=1
fi
done 

let pc=$pc1+$pc2+$pc3+$pc4

if [ $pc != 4 ]; then
echo "================================" >> $stats_log
echo `date` >> $stats_log
echo "JBoss lost --> Restarting Now" >> $stats_log
cp $jboss_log_root/$jboss_log_name $jboss_log_root/$sysdate.log
if [ -f $jboss_log_root/$sysdate.log ];then
echo "JBoss log file $sysdate.log had been backuped" >> $stats_log
for x in `ps -ef | grep jboss | grep java | grep -v grep | awk '{print $2}'`
do
echo "JBoss Process $x had been killed" >> $stats_log
#kill -9 $x
done
echo "JBoss killed" >> $stats_log
sleep 10s
#. /root/jboss_start.sh
sleep 30s
echo `date` >> $stats_log
echo "JBoss started" >> $stats_log
echo "================================" >> $stats_log
echo " " >> $stats_log
echo " " >> $stats_log
else
echo "ERROR!! Can not local backup logfile" >> $stats_log
fi
fi 

rm -rf $lock
