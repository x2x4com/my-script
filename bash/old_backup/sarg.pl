#!/usr/bin/perl -w

$squid_log_pwd="/var/log/squid";

chomp($date_y=`/bin/date +%y`);
chomp($date_m=`/bin/date +%m`);
chomp($date_d=`/bin/date +%d`);
$date_d-=1; #means $date_d=$date_d-1

if ($date_d < 10){
	$date_d="0"."$date_d";
}

$date_now="$date_y"."$date_m"."$date_d";

#`/usr/bin/sarg >> /var/log/sarg_back.log 2&>1`;
#chomp($sarg_stats=`/bin/cat /var/log/sarg_back.log | cut -d  "." -f 2 | cut -d ":" -f 4 | cut -d " " -f 2`); ##
$sarg_stats=100;##

if ($sarg_stats == 100){

##print "${date_y}${date_m}${date_d}\n$date_now\n$sarg_stats\n";
chdir("$squid_log_pwd");
chomp($access_log=`/bin/ls -l | /bin/grep access.log | cut -d ":" -f 2 | cut -d " " -f 2`);
chomp($cache_log=`/bin/ls -l | /bin/grep cache.log | cut -d ":" -f 2 | cut -d " " -f 2`);
chomp($store_log=`/bin/ls -l | /bin/grep store.log | cut -d ":" -f 2 | cut -d " " -f 2`);
##print "$access_log $cache_log $store_log $squid_log_pwd\n";

if ($access_log ne "access.log"){
	print "Files ERROR! Please check file access.log in /var/log/squid\n";
}elsif ($cache_log ne "cache.log"){
	print "Files ERROR! Please check file cache.log in /var/log/squid\n";
}elsif ($store_log ne "store.log"){
	print "Files ERROR! Please check file store.log in /var/log/squid\n";
}else{
	`/bin/tar -zcf $date_now.tar.gz $access_log $cache_log $store_log`;
	$check_tar=`/bin/ls -l | grep $date_now | cut -d ":" -f 2 | cut -d " " -f 2 | cut -d "." -f 1`;
	if ($date_now != $check_tar){
		print "Tar Error!!"
	}else{
		`/bin/rm -rf $access_log`;
		`/sbin/service squid reload`;

	}
}
}else{
print "ERROR!!Maybe command sarg running problem!\n";
}
