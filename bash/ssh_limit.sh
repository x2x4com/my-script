#!/bin/bash


usage() {
    echo "This script will use iptables to limit ssh connect"
    echo "Usage: `basename $0` connect_count timelimit" 
	exit 99
}

if [ $# -ne 2 ];then
	echo "Parameter Error"
	usage
fi

if [ $UID -ne 0 ];then
	echo "You are not root,please run me as root"
	exit 99
fi

err_run() {
	echo
	echo "[Error] when $step"
	exit 99
}
test_parm=`perl -e "if ( ($1 =~ /\d+/) && ($2 =~ /\d+/) ) { print \"1\n\"; } else { print \"0\n\";}"`
#echo $test_parm
if [ $test_parm -eq 1 ]
then
hitcount=$1
timelimit=$2
else
	echo "Parameter Error"
	usage
fi

echo "This script will limit same ip alow $hitcount times connect request in $timelimit sec"
sleep 1

if [ `iptables -L | grep SSH_CHECK | wc -l` -eq 1 ];then
	echo "[Error] Find SSH_CHECK chain"
	exit 99
fi

step="Step 0: Clean up iptables"
echo $step
echo "Backup your iptables rules"
today=`date +%y%m%d`
iptables-save > /tmp/$today.iptables
if [ $? -eq 0 ];then
	echo "Your configure had been saved to /tmp/$today.iptables"
else
	echo "[Error] Save iptables configure failed..."
	exit 99
fi

echo "Delete SSH rules in $today.iptables"
sed -e '/--dport 22/d' /tmp/$today.iptables > /tmp/$today.iptables.tmp
if [ $? -eq 0 ];then
	rm -rf /tmp/$today.iptables && mv /tmp/$today.iptables.tmp /tmp/$today.iptables
	if [ $? -ne 0 ];then
		echo "[Error] Failed to delete rules (delete or rename file failed)"
		exit 99
	fi
else 
	echo "[Error] Failed to delete rules"
	exit 99
fi

echo "Replace /tmp/$today.iptables now ..."

perl <<'EOF'
use POSIX qw(strftime);
$today = POSIX::strftime("%y%m%d", localtime(time));
open LOAD, "</tmp/$today.iptables" ;
open SAVE, ">/tmp/$today.iptables_new" ;
foreach (<LOAD>) {
    if (/^:OUTPUT ACCEPT/) {
    print SAVE $_ ;
    print SAVE ":SSH_CHECK - [0:0]\n" ;
	print SAVE "-A INPUT -p tcp -m tcp --dport 22 -m state --state NEW -j SSH_CHECK\n" ;
	print SAVE "-A SSH_CHECK -m recent --set --name SSH --rsource\n" ;
	print SAVE "-A SSH_CHECK -m recent --update --seconds 60 --hitcount 5 --name SSH --rsource -j DROP\n" ;
	print SAVE "-A SSH_CHECK -p tcp -m tcp --dport 22 -j ACCEPT\n" ;
    next;
    }
    print SAVE $_ ;
}
close LOAD;
close SAVE;
EOF

echo "Restore your iptabes configure"

iptables-restore < /tmp/$today.iptables_new
if [ $? -ne 0 ];then
	echo "Restore failed, please restore /tmp/$today.iptables by yourself"
fi

echo "If you use RedHat base Linux, please run /etc/init.d/iptables save"
exit 0
