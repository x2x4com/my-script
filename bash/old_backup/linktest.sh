#!/bin/bash 
# test ADSL link 
# 
address1=202.96.209.6
address2=www.online.sh.cn 
address3=sh.vnet.cn
result1=`/bin/ping -c 1 $address1 -w 10 | /bin/grep ttl | /bin/cut -d " " -f 8` 
result2=`/bin/ping -c 1 $address2 -w 10 | /bin/grep ttl | /bin/cut -d " " -f 8` 
result3=`/bin/ping -c 1 $address3 -w 10 | /bin/grep ttl | /bin/cut -d " " -f 8` 
if [ -z $result1 ] && [ -z $result2 ] && [ -z $result3 ]; 
then 
echo "ADSL-LOG >>" "Time="`/bin/date +%F`","`/bin/date +%k`":"`/bin/date +%M` "Status=Offline,Redial now" >> /var/log/adsl-status.log
/root/script/redial.sh
#else
#echo "ADSL-LOG >>" "Status=OK" >> /var/log/adsl-status.log
fi 

