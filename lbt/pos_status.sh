#!/bin/ksh

log_root=log
log_name=pos_status.log

ka=0
kb=0
kc=0
kd=0
ko=0

i=1
while [ $i -eq 1 ]
do
sysdate=`date +%Y%m%d%H%M%S`
tohost=`ps -ef | grep tohost | grep -c -v grep`
skernel=`ps -ef | grep skernel | grep -c -v grep`
tcpcom=`ps -ef | grep tcpcom | grep -c -v grep`
shorttcp=`ps -ef | grep shorttcp | grep -c -v grep`
#echo "$tohost,$skernel,$tcpcom,$shorttcp"
if [ $tohost -eq 0 ]
then
	if [ $ka -eq 0 ]
	then
		echo `date` >> $log_root/$log_name
		echo "Tohost lost!!!" >> $log_root/$log_name
		echo " " >> $log_root/$log_name
		ka=1
	fi
fi 

if [ $skernel -eq 0 ]
then
	if [ $kb -eq 0 ]
	then
		echo `date` >> $log_root/$log_name
		echo "skernel lost!!!" >> $log_root/$log_name
		echo " " >> $log_root/$log_name
		kb=1
	fi
fi

if [ $tcpcom -eq 0 ]
then
	if [ $kc -eq 0 ]
	then
		echo `date` >> $log_root/$log_name
		echo "tcpcom lost!!!" >> $log_root/$log_name
		echo " " >> $log_root/$log_name
		kc=1
	fi
fi

if [ $shorttcp -eq 0 ]
then
	if [ $kd -eq 0 ]
	then
		echo `date` >> $log_root/$log_name
    		echo "shorttcp lost!!!" >> $log_root/$log_name
    		echo " " >> $log_root/$log_name
		kd=1
	fi
fi

let ko=$ka+$kb+$kc+$kd
#echo $ko
if [ $ko -eq 4 ]
then
	exit 0
else
	ko=0
fi
done
