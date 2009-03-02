#!/bin/bash
#******************************************************
# This script will auto install qmail(with vpopmail)
#				vpopmail
#				daemontools
#				ucspi-tcp
#				courier-imap
#
#
#******************************************************

BASE_DIR=`pwd`
LOG="$BASE_DIR/install.log"
ERR_LOG="$BASE_DIR/err.log"
stats="$BASE_DIR/install.stats"
temp="/tmp/installqmail"
ERR=99


## function ##
## error ##
err() {
	err_msg=$1
	echo "$err_msg"
	echo "Details:"
	echo "[`date +%y-%m-%d` `date +%H:%M:%S`] $err_msg" >> $ERR_LOG
	echo "[`date +%y-%m-%d` `date +%H:%M:%S`] $err_msg" >> $LOG
	tail -10 $LOG
	exit $ERR
}

## Check UID ##
if [ $UID -ne 0 ]
then
	err "Please `basename $0` as root"
fi

## Requie setup.pl ##
if [ -f "$BASE_DIR/setup.pl" ]
then
	chmod +x setup.pl
else
	err "Can not find requie file: $BASE_DIR/setup.pl"
fi

## check all files ##
$BASE_DIR/setup.pl check_files
if [ $? -ne 0 ]
then
	err "file check error"
fi

## requie confiure file setup.conf ##
if [ ! -f "$BASE_DIR/setup.conf" ]
then
	$BASE_DIR/setup.pl init_conf
	if [ $? -ne 0 ]
	then
		err "Init configure error"
	fi
fi

if [ ! -f "$BASE_DIR/setup.conf" ]
then
	err "Can not find setup.conf"
fi

. $BASE_DIR/setup.conf
if [ $? -ne 0 ]
then 
	err "Can not inculde setup.conf"
fi

## requie install stats file ##
if [ -f "$stats" ]
then
	. $stats
	#mv $stats ${stats}.bak
	#cat /dev/null > $stats
else
	$BASE_DIR/setup.pl init_stats
fi


## Step 1: yum install need rpms ##
if [ $step1 -ne 1 ]
then
echo "Yum install need rpms"
yum -y install httpd php php-mysql mysql mysql-server mysql-devel gdbm gdbm-devel openssl openssl-devel stunnel krb5-devel spamassassin
if [ $? -ne 0 ]
then
	err "yum install error"
fi
echo "Yum install finished"
sed -i -e "s/step1=\(.*\)/step1=1/g" $stats
fi

## check mysql online ##
if [ ` netstat -antp | grep LISTEN | grep 3306 | wc -l` -gt 0 ]
then
	echo "Mysql is online"
else
	/etc/init.d/mysqld start
	if [ $? -ne 0 ]
	then 
		err "Mysql is not online"
	fi
fi

## check mysql root passwd ##
echo "Test mysql root passwd"
mysql -u$mysql_root -p$mysql_pass <<_EOF_
show databases;
use mysql;
select host,user from user;
_EOF_
if [ $? -ne 0 ]
then
	err "error mysql root password wrong"
fi

## Step 2: check sendmail status ##
if [ $step2 -ne 1 ]
then
echo "Check and uninstall sendmail program"
if [ `netstat -antp | grep LISTEN | grep ":25" | wc -l` -gt 0 ]
then
	/etc/init.d/sendmail stop
	if [ $? -ne 0 ]
	then
		err "Can not stop sendmail"
	fi
fi
rpm -e `rpm -qa | grep "sendmail-"` --nodeps
echo "check and uninstall sendmail finish"


if [ `netstat -ant | grep LISTEN | grep -e ":110" -e ":143" -e "995" -e "587" | wc -l` -gt 0 ]
then
	err "Find some others pop3 imap program running, please uninstall it"
fi 

sed -i -e "s/step2=\(.*\)/step2=1/g" $stats
fi

## make a temp directory to install ##
if [ ! -d "$temp" ]
then
mkdir -p $temp
if [ $? -ne 0 ]
then
	err "Can not create $temp directory "
fi
fi

## create qmail and vpopmail home ##
## Step 3: Create qmail home and users ##
if [ $step3 -ne 1 ]
then
echo "create qmail home"
mkdir -p $qmail_dir
echo "add need users and groups"
groupadd nofiles
if [ $? -ne 0 ]
then
	err "error add group nofiles"
fi
groupadd qmail
if [ $? -ne 0 ]
then
	err "error add group qmail"
fi
useradd alias -g nofiles -d $qmail_dir/alias -s /sbin/nologin
useradd qmaild -g nofiles -d $qmail_dir -s /sbin/nologin
useradd qmaill -g nofiles -d $qmail_dir -s /sbin/nologin
useradd qmailp -g nofiles -d $qmail_dir -s /sbin/nologin
useradd qmailq -g qmail -d $qmail_dir -s /sbin/nologin
useradd qmailr -g qmail -d $qmail_dir -s /sbin/nologin
useradd qmails -g qmail -d $qmail_dir -s /sbin/nologin
sed -i -e "s/step3=\(.*\)/step3=1/g" $stats
fi

## Step 4: Create vpop user and home
if [ $step4 -ne 1 ]
then
echo "delete user who uid is 89"
userdel -r `sudo grep ":89" /etc/passwd | cut -d ":" -f 1`

groupadd vchkpw -g 89
if [ $? -ne 0 ]
then
    err "error groupadd vchkpw"
fi
useradd vpopmail -u 89 -g vchkpw
if [ $? -ne 0 ]
then
    err "error useradd vpopmail"
fi
sed -i -e "s/step4=\(.*\)/step4=1/g" $stats
fi

echo "link a TLS patch for include"
ln -s /usr/kerberos/include/com_err.h /usr/include/

echo "delete sendmail link"
rm -rf /usr/sbin/sendmail


## Step 5: init qmail ##
if [ $step5 -ne 1 ]
then
echo "Init qmail install"
cd $BASE_DIR
cp source/netqmail-1.05.tar.gz $temp >>$LOG 2>&1
if [ $? -ne 0 ]
then
    err "Can not copy netqmail to temp dir"
fi
cd $temp
tar -zxvf netqmail-1.05.tar.gz >>$LOG 2>&1
if [ $? -ne 0 ]
then
    err "Error when tar -zxvf netqmail-1.05.tar.gz"
fi
cd netqmail-1.05
./collate.sh >>$LOG 2>&1
if [ $? -ne 0 ]
then
    err "Error when running collate.sh"
fi
echo "Init qmail finish"
sed -i -e "s/step5=\(.*\)/step5=1/g" $stats
fi


## Step 6: install daemontools ##
if [ $step6 -ne 1 ]
then
echo "Install daemontools"
cd $BASE_DIR
cp source/daemontools-0.76.tar.gz $temp >>$LOG 2>&1
if [ $? -ne 0 ]
then
    err "Can not copy daemontools to temp dir"
fi
cd $temp
tar -zxvf daemontools-0.76.tar.gz >>$LOG 2>&1
if [ $? -ne 0 ]
then
    err "error when tar -zxvf daemontools-0.76.tar.gz"
fi
cd admin/daemontools-0.76
patch -p1 < $BASE_DIR/patchs/daemontools-0.76.errno.patch >>$LOG 2>&1
if [ $? -ne 0 ]
then
    err "error when patch daemontools"
fi
cd ..
echo "install to /usr/local"
cp -r daemontools-0.76 /usr/local/.
ln -s /usr/local/daemontools-0.76 /usr/local/daemontools
cd /usr/local/daemontools
package/install >>$LOG 2>&1
if [ $? -ne 0 ]
then
    err "error install daemontools on /usr/local/daemontools"
fi

sleep 5
if [ `ps -ef | grep svscan | grep -v grep | wc -l` -gt 0 ]
then
	echo "daemontools install finish, please check process list info: "
	ps ax | grep svscan | grep -v grep
else
	err "Can not fined daemontools process"
fi
sed -i -e "s/step6=\(.*\)/step6=1/g" $stats
fi


## Step 7: install ucspi-tcp ##
if [ $step7 -ne 1 ]
then
echo "Install UCSPI-TCP server"
cd $BASE_DIR
cp source/ucspi-tcp-0.88.tar.gz $temp >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error when cp source/ucspi-tcp-0.88.tar.gz temp"
fi
cd $temp
tar zxvf ucspi-tcp-0.88.tar.gz >>$LOG 2>&1
if [ $? -ne 0 ]
then
    err "error when tar zxvf ucspi-tcp-0.88.tar.gz"
fi
cd ucspi-tcp-0.88
patch -p1 < $BASE_DIR/patchs/ucspi-tcp-0.88.errno.patch >>$LOG 2>&1
if [ $? -ne 0 ]
then
    err "error when patch -p1 < ../ucspi-tcp-0.88.errno.patch"
fi
make >>$LOG 2>&1
if [ $? -ne 0 ]
then
    err "error when make ucspi-tcp-0.88"
fi
make setup check >>$LOG 2>&1
if [ $? -ne 0 ]
then
    err "error when make setup check ucspi-tcp-0.88"
fi

echo "Install UCSPI-TCP server finished"
sed -i -e "s/step7=\(.*\)/step7=1/g" $stats
fi

## Step 8: patch qmail source ##
if [ $step8 -ne 1 ]
then
echo "patch qmail source \"qmail-smtpd.c\""
cd $temp/netqmail-1.05/netqmail-1.05
if [ -w "qmail-smtpd.c" ] 
then
	sed -i -e "s/void straynewline() { out(\"451 See/void straynewline() { out(\"553 See/g" qmail-smtpd.c
	if [ $? -ne 0 ]
	then
		err "error patch qmail-smtp.c"
	fi
else
	err "can not find `pwd`/qmail-smtpd.c"
fi
sed -i -e "s/step8=\(.*\)/step8=1/g" $stats
fi

## Step 9: install qmail-engine ##
if [ $step9 -ne 1 ]
then
echo "Install qmail-engine"
cd $temp/netqmail-1.05/netqmail-1.05
make >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error make qmail"
fi
make setup check >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error make setup check qmail"
fi
sed -i -e "s/step9=\(.*\)/step9=1/g" $stats
fi

## Step 10: Configure qmail and create startup##
if [ $step10 -ne 1 ]
then
echo "Configure qmail and create startup script"
cd $temp/netqmail-1.05/netqmail-1.05
## create your contorl files ##
./config-fast $domain

## setup your default account ##
cd $qmail_dir/alias
echo "webmaster@$domain" > .qmail-postmaster
echo "webmaster@$domain" > .qmail-mailer-daemon  
echo "webmaster@$domain" > .qmail-root  
chmod 644 /var/qmail/alias/.qmail*

## enable SPF ##
echo "enable SPF"
echo './Maildir/' > $qmail_dir/control/defaultdelivery
echo '3' > $qmail_dir/control/spfbehavior

## add man page ##
echo "add man page"
echo "MANPATH $qmail_dir/man" >> /etc/man.config

## create monitor dir and log files ##
echo "Create monitor dir and log files"
mkdir -p $qmail_dir/supervise/qmail-send/log
mkdir -p $qmail_dir/supervise/qmail-smtpd/log
mkdir -p $qmail_dir/supervise/qmail-pop3d/log
mkdir -p $qmail_dir/supervise/qmail-pop3ds/log
cd $BASE_DIR
cp source/toaster-scripts-0.9.1.tar.gz $temp >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error cp source/toaster-scripts-0.9.1.tar.gz temp"
fi
cd $temp
tar -zxvf toaster-scripts-0.9.1.tar.gz >>$LOG 2>&1
if [ $? -ne 0 ]
then
	error "error tar -zxvf toaster-scripts-0.9.1.tar.gz"
fi
cp toaster-scripts-0.9.1/send.run $qmail_dir/supervise/qmail-send/run
cp toaster-scripts-0.9.1/send.log.run $qmail_dir/supervise/qmail-send/log/run
cp toaster-scripts-0.9.1/smtpd.run $qmail_dir/supervise/qmail-smtpd/run
cp toaster-scripts-0.9.1/smtpd.log.run $qmail_dir/supervise/qmail-smtpd/log/run
cp toaster-scripts-0.9.1/pop3d.run $qmail_dir/supervise/qmail-pop3d/run
cp toaster-scripts-0.9.1/pop3d.log.run $qmail_dir/supervise/qmail-pop3d/log/run
cp toaster-scripts-0.9.1/pop3ds.run $qmail_dir/supervise/qmail-pop3ds/run
cp toaster-scripts-0.9.1/pop3ds.log.run $qmail_dir/supervise/qmail-pop3ds/log/run

echo 20 > $qmail_dir/control/concurrencyincoming
chmod 644 $qmail_dir/control/concurrencyincoming
chmod 755 $qmail_dir/supervise/qmail-send/run
chmod 755 $qmail_dir/supervise/qmail-send/log/run
chmod 755 $qmail_dir/supervise/qmail-smtpd/run
chmod 755 $qmail_dir/supervise/qmail-smtpd/log/run
chmod 755 $qmail_dir/supervise/qmail-pop3d/run
chmod 755 $qmail_dir/supervise/qmail-pop3d/log/run
chmod 755 $qmail_dir/supervise/qmail-pop3ds/run
chmod 755 $qmail_dir/supervise/qmail-pop3ds/log/run
mkdir -p /var/log/qmail/smtpd
mkdir -p /var/log/qmail/pop3d
mkdir -p /var/log/qmail/pop3ds
chown -R qmaill /var/log/qmail

## install startup script ##
cp toaster-scripts-0.9.1/rc $qmail_dir/rc
chmod 755 $qmail_dir/rc
cp toaster-scripts-0.9.1/qmailctl $qmail_dir/bin/.
chmod 755 $qmail_dir/bin/qmailctl
ln -s $qmail_dir/bin/qmailctl /usr/bin
ln -s $qmail_dir/bin/sendmail /usr/sbin/sendmail
rm -rf /usr/lib/sendmail
ln -s $qmail_dir/bin/sendmail /usr/lib/sendmail

## start qmail-send & qmail-smtp via daemontools ##
ln -s $qmail_dir/supervise/qmail-send $qmail_dir/supervise/qmail-smtpd /service
sed -i -e "s/step10=\(.*\)/step10=1/g" $stats
fi

## install vpopmail ##
## Step 11: init vpopmail install ##
if [ $step11 -ne 1 ]
then
echo "Install vpopmail"
mkdir -p $vpopmail_dir/etc
echo "$domain" > $vpopmail_dir/etc/defaultdomain

## disable open relays ##
echo '127.0.0.1:allow,RELAYCLIENT=""' > $vpopmail_dir/etc/tcp.smtp
cd $vpopmail_dir/etc ; tcprules tcp.smtp.cdb tcp.smtp.tmp < tcp.smtp
cd -

## setup vpopmail mysql account info"
echo "localhost|0|$vpopmail_user|$vpopmail_pass|$vpopmail_table" > $vpopmail_dir/etc/vpopmail.mysql
chmod 640 $vpopmail_dir/etc/vpopmail.mysql
chown -R vpopmail.vchkpw $vpopmail_dir/etc
sed -i -e "s/step11=\(.*\)/step11=1/g" $stats
fi

## Step 12: add vpopmail users and tables to mysql ##
if [ $step12 -ne 1 ]
then
echo "add vpopmail tables"
mysql -u$mysql_root -p$mysql_pass <<_____EOF_____
CREATE DATABASE $vpopmail_table;
GRANT select,insert,update,delete,create,drop ON $vpopmail_table.* TO $vpopmail_user@localhost IDENTIFIED BY "$vpopmail_pass";
FLUSH PRIVILEGES;
_____EOF_____
if [ $? -ne 0 ]
then
	echo "create table error, please create table normally"
	err "create vpopmail tables error"
fi
sed -i -e "s/step12=\(.*\)/step12=1/g" $stats
fi

## Step 13: install vpopmail ##
if [ $step13 -ne 1 ]
then
echo "Configure and make vpopmail"
cd $BASE_DIR
cp source/vpopmail-5.4.25.tar.gz $temp >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error cp source/vpopmail-5.4.25.tar.gz temp"
fi
cd $temp
tar -zxvf vpopmail-5.4.25.tar.gz >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "tar -zxvf vpopmail-5.4.25.tar.gz"
fi
cd vpopmail-5.4.25
./configure --enable-incdir=/usr/include/mysql --enable-libdir=/usr/lib/mysql --disable-roaming-users --enable-logging=p --disable-passwd --enable-clear-passwd --disable-domain-quotas --enable-auth-module=mysql --enable-auth-logging --enable-sql-logging --disable-valias --disable-mysql-limits --enable-learn-passwords --enable-spamassassin --enable-valias >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error configure vpopmail"
fi
make >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error make vpopmail"
fi
make install-strip >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error make install vpopmail"
fi
sed -i -e "s/step13=\(.*\)/step13=1/g" $stats
fi

## Step 14: config vpopmail##
if [ $step14 -ne 1 ]
then
## add vpopmail to system patch ##
echo "add vpopmail to system patch"
echo 'export PATH=$PATH:/home/vpopmail/bin' >> /etc/profile
source /etc/profile

## add first domain ##
echo "add first domain: $domain"
vadddomain $domain $post_pass >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error vadddomain $domain"
fi

cd $BASE_DIR
## add over quota message ##
echo "add over quota message"
cp docs/*.msg $temp
cd $temp
sed -i -e "s/domain.com/$domain/g" quotawarn.msg
cp quotawarn.msg $vpopmail_dir/domains/$domain/.quotawarn.msg
cp over-quota.msg $vpopmail_dir/domains/$domain/.over-quota.msg

## create vpopmail start script ##
cp $temp/toaster-scripts-0.9.1/vpopmailctl $qmail_dir/bin >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "cp $temp/toaster-scripts-0.9.1/vpopmailctl $qmail_dir/bin"
fi
ln -s $qmail_dir/bin/vpopmailctl /usr/bin
chmod 755 $qmail_dir/bin/vpopmailctl

ln -s $qmail_dir/supervise/qmail-pop3d /service
ln -s $qmail_dir/supervise/qmail-pop3ds /service
sed -i -e "s/step14=\(.*\)/step14=1/g" $stats
fi

chown -R vpopmail:vchkpw $qmail_dir/spam

## patch qmail for vpopmail support ##
## Step 15: install libdomain-keys ##
if [ $step15 -ne 1 ]
then
echo "Patch qmail for vpopmail support"
echo "prepare libdomain-keys"
cd $BASE_DIR
cp source/libdomainkeys-0.68.tar.gz $temp/. >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error copy libdomainkeys-0.68.tar.gz to temp"
fi
cd $temp
tar -zxvf libdomainkeys-0.68.tar.gz >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error tar -zxvf libdomainkeys-0.68.tar.gz"
fi
cd libdomainkeys-0.68
make >>$LOG 2>&1
if [ $? -ne 0 ]
then
	make clean
	echo -lresolv > dns.lib
	make
	if [ $? -ne 0 ]
	then
		err "error make libdomainkeys"
	fi
fi 
sed -i -e "s/step15=\(.*\)/step15=1/g" $stats
fi

## Step 16: patch qmail with toaster ##
if [ $step16 -ne 1 ]
then
echo "patch qmail for tls, esmtp (toaster)"
cd $temp/netqmail-1.05/netqmail-1.05
cp $BASE_DIR/source/qmail-toaster-0.9.1.patch.bz2 $temp/.
bunzip2 -c ../../qmail-toaster-0.9.1.patch.bz2 | patch -p0 >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error patch qmail for tls, esmtp (toaster)"
fi

qmailctl stop

make >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error make qmail"
fi
make setup check >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error make setup check qmail"
fi

## create SSL key ##
echo "create SSL key"
make cert
if [ $? -ne 0 ]
then 
	err "error make cert"
fi
make tmprsadh
if [ $? -ne 0 ]
then
	err "error make tmprsadh"
fi
chown -R vpopmail:qmail $qmail_dir/control/clientcert.pem $qmail_dir/control/servercert.pem

## create cron for update keys everyday ##
echo "create cron for update keys everyday"
if [ ! -f "/var/spool/cron/root" ]
then
	touch /var/spool/cron/root
	chmod 600 /var/spool/cron/root
fi
echo "01 01 * * * $qmail_dir/bin/update_tmprsadh > /dev/null 2>&1" >> /var/spool/cron/root
/etc/init.d/crond restart
sed -i -e "s/step16=\(.*\)/step16=1/g" $stats
fi

## install imap ##
## Step 17: install authlib ##
if [ $step17 -ne 1 ]
then
echo "Install authlib"
cd $BASE_DIR
cp source/courier-authlib-0.58.tar $temp/. >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error copy courier-authlib-0.58.tar to temp"
fi
cd $temp
tar -jxf courier-authlib-0.58.tar >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error tar -jxf courier-authlib-0.58.tar"
fi
cd courier-authlib-0.58
./configure --prefix=/usr/local --exec-prefix=/usr/local --with-authvchkpw --without-authldap --without-authmysql --disable-root-check --with-ssl --with-authchange pwdir=/usr/local/libexec/authlib --with-redhat >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error configure courier-authlib-0.58"
fi
make >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error make courier-authlib-0.58"
fi
make install >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error make install courier-authlib-0.58"
fi
make install-configure >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error make install-configure courier-authlib-0.58"
fi
echo "fix courier authlib configure"
sed -i -e "s/authmodulelist=\"authuserdb authpam authcustom authvchkpw authpipe\"/authmodulelist=\"authvchkpw\"/g" -e "s/authmodulelistorig=\"authuserdb authpam authcustom authvchkpw authpipe\"/authmodulelistorig=\"authvchkpw\"/g" -e "s/daemons=5/daemons=2/g" /usr/local/etc/authlib/authdaemonrc

/usr/local/sbin/authdaemond start >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error start authdaemond"
fi

if [ `ps -ef | grep authlib | grep -v grep| wc -l` -lt 2 ]
then
	err "error authlib not start, please check and reinstall it"
fi

echo "/usr/local/sbin/authdaemond start" >> /etc/rc.local
sed -i -e "s/step17=\(.*\)/step17=1/g" $stats
fi

## Step 18: install courier-imap ##
if [ $step18 -ne 1 ]
then
echo "install courier-imap"
cd $BASE_DIR
cp source/courier-imap-4.1.1.tar.bz2 $temp/. >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error copy courier-imap-4.1.1.tar.bz2 to temp"
fi
cd $temp
tar -jxf courier-imap-4.1.1.tar.bz2
if [ $? -ne 0 ]
then
	err "error tar -jxf courier-imap-4.1.1.tar.bz2"
fi
cd courier-imap-4.1.1
if [ $? -ne 0 ]
then
	err "error su to vpopmail"
fi
sudo -u vpopmail ./configure --with-redhat >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error sudo -u vpopmail ./configure courier-imap"
fi
sudo -u vpopmail make  >>$LOG 2>&1
if [ $? -ne 0 ]
then
	err "error sudo -u vpopmail make"
fi
make install-strip
if [ $? -ne 0 ]
then
	err "error make install-strip"
fi
make install-configure
if [ $? -ne 0 ]
then
	err "error make install-configure"
fi

## configure imap ##
if [ -f "/usr/lib/courier-imap/etc/authdaemonrc" ]
then
	mv "/usr/lib/courier-imap/etc/authdaemonrc" "/usr/lib/courier-imap/etc/authdaemonrc.orig"
fi
ln -s /usr/local/etc/authlib/authdaemonrc /usr/lib/courier-imap/etc/.
## make imapd imapd-ssl startup ##
if [ -f "/usr/lib/courier-imap/etc/imapd" ]
then
	sed -i -e "s/IMAPDSTART=[N|n][O|o]/IMAPDSTART=YES/g" /usr/lib/courier-imap/etc/imapd
else
	err "Can not find /usr/lib/courier-imap/etc/imapd"
fi

if [ -f "/usr/lib/courier-imap/etc/imapd-ssl" ]
then
	sed -i -e "s/IMAPDSSLSTART=[N|n][O|o]/IMAPDSSLSTART=YES/g" -e "s/IMAPDSTARTTLS=[N|n][O|o]/IMAPDSTARTTLS=YES/g" /usr/lib/courier-imap/etc/imapd-ssl
else
	err "Can not find /usr/lib/courier-imap/etc/imapd-ssl"
fi

if [ -f "/usr/lib/courier-imap/etc/imapd.cnf" ]
then
	sed -i -e "s/C=[a-zA-Z ]*/C=CN/g" -e "s/ST=[a-zA-Z ]*/ST=SH/g" -e "s/L=[a-zA-Z ]*/L=Shanghai/g" -e "s/CN=[a-zA-Z ]*/CN=$domain/g" -e "s/emailAddress=\(.*\)@\(.*\)/\1@$domain/g" /usr/lib/courier-imap/etc/imapd.cnf
fi

if [ -f "/usr/lib/courier-imap/etc/pop3d.cnf" ]
then
	sed -i -e "s/C=[a-zA-Z ]*/C=CN/g" -e "s/ST=[a-zA-Z ]*/ST=SH/g" -e "s/L=[a-zA-Z ]*/L=Shanghai/g" -e "s/CN=[a-zA-Z ]*/CN=$domain/g" -e "s/emailAddress=\(.*\)@\(.*\)/\1@$domain/g" /usr/lib/courier-imap/etc/pop3d.cnf
fi

## disable pop3 pop3-ssl ##
if [ -f "/usr/lib/courier-imap/etc/pop3d" ]
then
	sed -i -e "s/POP3DSTART=\(.*\)/POP3DSTART=NO/g" /usr/lib/courier-imap/etc/pop3d
fi
if [ -f "/usr/lib/courier-imap/etc/pop3d-ssl" ]
then
	sed -i -e "s/POP3DSSLSTART=\(.*\)/POP3DSSLSTART=NO/g" -e "s/POP3_STARTTLS=\(.*\)/POP3_STARTTLS=NO/g" /usr/lib/courier-imap/etc/pop3d-ssl
fi

## make imap startup ##
cp courier-imap.sysvinit /etc/rc.d/init.d/courier-imap
if [ $? -ne 0 ]
then
	err "error cp startup script to init dir"
fi
chmod 755 /etc/rc.d/init.d/courier-imap
if [ $? -ne 0 ]
then
	err "error chmod 755 to courier-imap"
fi

/etc/init.d/courier-imap start
sleep 5
if [ `netstat -ant | grep -e "LISTEN" | grep -e "143" -e "993" |wc -l` -lt 2 ]
then
	err "error check imap port 143 and 993, please check and reinstall imap"
fi

echo 'sleep 1' >> /etc/rc.local
echo '/etc/init.d/courier-imap start' >> /etc/rc.local
sed -i -e "s/step18=\(.*\)/step18=1/g" $stats
fi

qmailctl start
vpopmail start

## ================================================== ##
echo "
Qmail engine and vpopmail install finish

Now, you can start with list command:
To start qmail-engine: qmailctl start
To start vpopmail : vpopmailctl start
Testing qmail-engine with: netstat -antp | grep 25
Testing pop3 with: netstat -antp | grep 110
Testing pop3-SSL with: netstat -antp | grep 995
Testing imap with: netstat -antp | grep 143
Testing imap SSL with: netstat -antp | grep 993

Any errors can find at: ps -ef | grep \"service errors\" | grep -v grep
"

