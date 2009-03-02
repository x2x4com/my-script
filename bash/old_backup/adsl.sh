#!/bin/bash 
#  
# 
log=/var/log/adsl.log
address1=202.96.209.6
address2=www.online.sh.cn 
address3=www.sina.com.cn
pid_file="/var/run/pppoe-adsl.pid"

function redial() {

	echo -n "====STOP ADSL====  " >> $log
	echo `date` >> $log
	echo >> $log
	#/usr/sbin/adsl-stop >> $log 2>&1
	for adsl_pid in `ps -ef | grep adsl | grep -v grep | awk '{print $2}'`
	do 
	echo -n `date` >> $log
	echo ": PID=$adsl_pid killed  " >> $log
	kill -9 $adsl_pid
	if [ $? -ne 0 ];then
		echo >> $log 
		echo "====ERROR==== when kill adsl $adsl_pid" >> $log
		echo >> $log
  fi
	done

	if [ -r $pid_file ];then
		/bin/rm -rf ${pid_file}*
	fi

echo -n "====START ADSL====  " >> $log
echo `date` >> $log
echo >> $log
/usr/sbin/adsl-start 2>> $log
if [ $? -ne 0 ];then
	echo >> $log
	echo "====ERROR====  when exec : /usr/sbin/adsl-start" >> $log
	echo>> $log
fi
sleep 30
return 8
}

function test_adsl_ip() {
	Extranet=`/sbin/ifconfig ppp0 | /bin/grep inet | awk '{print $2}'| /bin/cut -d : -f 2`
	if [ -n $Extranet ];then
		return 0
	else
		return 9
	fi
}

function restart_fw() {
echo "====START FIREWALL====  " >> $log
/etc/init.d/shorewall restart 2>> $log
if [ $? -ne 0 ];then
	echo >> $log
	echo "====ERROR==== when exec : /etc/init.d/shorewall restart" >> $log
	echo >> $log
fi
}

redialed=0
adsl_link_test=0
while [ $adsl_link_test -le 2 ]
do
test_adsl_ip
if [ $? -eq 9 ];then
	redial
	redialed=$?
	let adsl_link_test=$adsl_link_test+1
else
result1=`/bin/ping -c 1 $address1 -w 10 | /bin/grep ttl | /bin/cut -d " " -f 8`
result2=`/bin/ping -c 1 $address2 -w 10 | /bin/grep ttl | /bin/cut -d " " -f 8`
result3=`/bin/ping -c 1 $address3 -w 10 | /bin/grep ttl | /bin/cut -d " " -f 8`
	if [ -z $result1 ] && [ -z $result2 ] && [ -z $result3 ]; then
		echo -n "====Warning ADSL LOST====  " >> $log
		echo `date` >> $log
		redial
		redialed=$?
		let adsl_link_test=$adsl_link_test+1
	else
		adsl_link_test=5
	fi
fi
done

if [ $adsl_link_test -eq 3 ];then
	echo -n "====ERROR==== Try over 3 times, auto exit  " >> $log
	echo `date` >> $log
	echo
else
	echo "====test==== link ok  " >> $log
fi

if [ $redialed -eq 8 ];then
restart_fw
fi
