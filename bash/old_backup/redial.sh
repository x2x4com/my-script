#!/bin/sh 
#
#

##find adsl interface

log=/var/log/adsl-status.log
ppp_interface_count=`ifconfig -a | grep ppp -c`
echo $ppp_interface_count
if [ $ppp_interface_count -gt 1 ];then
	echo " " >> $log
	echo "ERROR!! Find $ppp_interface_count ppp interface" >> $log
	echo `ifconfig -a | grep ppp` >> $log
	exit 1
else
	for ppp_interface_count in 1
	do
	echo -n "====STOP ADSL====" >> $log
	echo `date` >> $log
	#/usr/sbin/adsl-stop >> $log 2>&1
	for adsl_pid in `ps -ef | grep adsl | grep -v grep | awk '{print $2}'`
	do 
	echo -n `date` >> $log
	echo ": PID=$adsl_pid killed" >> $log
	kill -9 $adsl_pid 
	done
	ppp_interface_count=`ifconfig -a | grep ppp -c`
	echo $ppp_interface_count
	pid_file="/var/run/pppoe-adsl.pid.pppoe"
	if [ -r $pid_file ];then
		/bin/rm -f $pid_file
	fi
	done
fi

echo -n "====START ADSL====" >> $log
echo `date` >> $log
/usr/sbin/adsl-start >> $log 2>&1
echo -n "====START FIREWALL====" >> $log
echo `date` >> $log
Extranet=`/sbin/ifconfig ppp0 | /bin/grep inet | awk '{print $2}'| /bin/cut -d : -f 2`
echo -n "====NOW IP IS $Extranet====" >> $log
echo `date`	

/etc/init.d/shorewall restart
. /root/script/linktest.sh
