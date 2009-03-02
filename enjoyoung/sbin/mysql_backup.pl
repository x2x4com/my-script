#!/usr/bin/perl
##################################################
#
# Script Name:		mysql_backup.pl
# Script Author:	Jacky Xu
# Create Date:		2008-09-18
# Function desc:	1, backup specified db
#	
#
# Usage:	mysql_backup.pl dbname:charset,dbname:charset,dbname:charset pre_release_name
#
##################################################

use strict;
use POSIX qw(strftime);

my $mysql_dump = '/usr/bin/mysqldump';
my $mysql_username = 'root';
my $mysql_password = '';
my $my_tar = '/bin/tar';
## It's default directory for save mysql dump file
my $admin_base = '/home/mongrel/db_backup';
my ($charset,@databases,$date_now);

### Please do not change easily ###
my $data_dir = "${admin_base}/data";
my $log_dir = "${admin_base}/log";
my $time_format = sub { my $time_now = POSIX::strftime("\[%Y-%m-%d %H:%M:%S\]", localtime(time));return $time_now;};

if ($ARGV[0] =~ /\w+:\w+(,\w+:\w+)*/){
	(@databases) = split /,/, $ARGV[0]	;
} else {
	@databases = ('enjoyoung_production:utf8');
}

if (defined $ARGV[1]) {
	$date_now = $ARGV[1];
} else {
	$date_now = POSIX::strftime("%Y-%m-%d_%H%M", localtime(time));
}

## open logfile ##
open LOG, ">>$log_dir/mysql_backup.log" or my $no_log = 1;
select LOG unless ($no_log) ;

sub mysql_dump {
	my ($dbname,$save,$charset) = @_;
	my ($dumpstat ,$tarstat,$unlinkstat);
	print $time_format->() ." Start to dump $dbname now\n";
	
	$dumpstat = system "$mysql_dump","-u${mysql_username}", "-p${mysql_password}", "--databases", "$dbname", "--default-character-set=$charset","--result-file=${save}";
	if ( $dumpstat == 0 ) {
		print $time_format->() ." Dump $dbname successfully!\n";
		print $time_format->() ." Compress ${save} now\n";
		$tarstat = system "$my_tar","-zcPf","${save}.tar.gz","${save}";
		if ( $tarstat == 0 ) {
			print $time_format->() ." Compress $save successfully!\n";
			print $time_format->() ." Remove $save now\n";
			$unlinkstat = unlink "$save";
			if ( $unlinkstat == 1 ) {
				print $time_format->() ." Remove $save successfully!\n";
			} else {
				print $time_format->() ." Remove $save failure!\n";
			}
		} else {
			print $time_format->() ." Compress $save failure!\n";
		}
	} else {
		print $time_format->() ." Dump $dbname failure!\n";
	}
	if ( $dumpstat == 0 && $tarstat == 0 && $unlinkstat == 0 ) {
		return 0;
	} else {
		return 1;
	}
	undef $dumpstat,$tarstat,$unlinkstat;
}

foreach my $db_info (@databases) {
	my ($target,$charset) = split /:/, $db_info;
	my $data_save = "$data_dir/${target}_${date_now}_${charset}.sql";
	my $return = mysql_dump($target,$data_save,$charset);
}
