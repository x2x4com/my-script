#!/usr/bin/perl

##################################################
#
# Script Name:		sysBck.pl
# Script Author:	Jacky Xu
# Create Date:		2008-09-18
# Function desc:	1, backup all website
#					2, backup all mysql
#
# Usage:	sysBck.pl mysql|tomcat|all
#
##################################################

use POSIX qw(strftime);

my $mysql_dump = '/usr/bin/mysqldump';
my $mysql_username = 'root';
my $mysql_password = 'LBTmysql@2007!';
my $my_tar = '/bin/tar';
my $tomcat_home = '/data/tomcat';
my $admin_base = '/usr/local/sysAdmin';
my $host_ip = '172.16.0.201';
my @website = ( paybyfinger , livebytouch );

### Please do not change easily ###
my $admin_base = "${admin_base}/${host_ip}";
my $work_dir = "${admin_base}/sysBackup";
my $data_dir = "${admin_base}/data";
my $log_dir = "${admin_base}/log";
my $date_now = POSIX::strftime("%Y-%m-%d", localtime(time));
my $time_format = sub { my $time_now = POSIX::strftime("\[%Y-%m-%d %H:%M:%S\]", localtime(time));return $time_now;};
unless ($ARGV[0] =~ /(mysql|tomcat|all)/){
	die "Useage:\tsysBck.pl mysql|tomcat|all\n";
}
my $todo = $ARGV[0];

###
# test file exeable
###

sub mysql_dump {
	my ($dumpstat,$tarstat,$unlinkstat);
	print $time_format->() ." Start to dump $target now\n";
	$dumpstat = system "$mysql_dump","-uroot", '-pLBTmysql@2007!', "--databases", "${$target}{mysql_dbname}", "--default-character-set=utf8","--result-file=${$target}{mysql_data_save}";
	if ( $dumpstat == 0 ) {
		print $time_format->() ." Dump ${$target}{mysql_dbname} successfully!\n";
		print $time_format->() ." Compress ${$target}{mysql_data_save} now\n";
		$tarstat = system "$my_tar","-zcPf","${$target}{mysql_data_save}.tar.gz","${$target}{mysql_data_save}";
		if ( $tarstat == 0 ) {
			print $time_format->() ." Compress ${$target}{mysql_data_save} successfully!\n";
			print $time_format->() ." Remove ${$target}{mysql_data_save} now\n";
			$unlinkstat = unlink "${$target}{mysql_data_save}";
			if ( $unlinkstat == 1 ) {
				print $time_format->() ." Remove ${$target}{mysql_data_save} successfully!\n";
			} else {
				print $time_format->() ." Remove ${$target}{mysql_data_save} failure!\n";
			}
		} else {
			print $time_format->() ." Compress ${$target}{mysql_data_save} failure!\n";
		}
	} else {
		print $time_format->() ." Dump ${$target}{mysql_dbname} failure!\n";
	}
	if ( $dumpstat == 0 && $tarstat == 0 && $unlinkstat == 0 ) {
		return 0;
	} else {
		return 1;
	}
	undef $dumpstat,$tarstat,$unlinkstat;
}

sub website_backup {
	print $time_format->() ." Start backup $target website now\n";
	my $tarstat = system "$my_tar","-zcPf","${$target}{web_data_save}","${$target}{home}";
	if ( $tarstat == 0 ) {
		print $time_format->() ." Backup $target website successfully!\n";
		return 0;
	} else {
		print $time_format->() ." Backup $target website failure!\n";
		return 1;
	}
	undef $tarstat;
}

foreach $target (@website) {
	%{$target} = ( home => "${tomcat_home}/${target}/Tomcat_5.28",
					mysql_dbname => "${target}",
					mysql_data_save => "${data_dir}/${target}_${date_now}_utf8.sql",
					web_data_save => "${data_dir}/${target}_website_${date_now}.tar.gz");
	if ($target eq "livebytouch"){
		${$target}{mysql_dbname} = "livebytouch111";
	}
	if ( $todo eq "mysql" ) {
		&mysql_dump;
	} elsif ( $todo eq "tomcat" ) {
		&website_backup;
	} elsif ( $todo eq "all" ) {
		&mysql_dump;
		#sleep 5;
		&website_backup;
	}
}
