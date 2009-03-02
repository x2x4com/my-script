#!/usr/bin/perl


my $datafile,@data_match_info,$data_save_info,$mymonth,@filelist,$devip;
my $source = '/var/log';
my $user = 'hugo';

$mymonth = { '0' => 'Jan',
			'1' => 'Feb',
			'2' => 'Mar',
			'3' => 'Apr',
			'4' => 'May',
			'5' => 'Jun',
			'6' => 'Jul',
			'7' => 'Aug',
			'8' => 'Sep',
			'9' => 'Oct',
			'10' => 'Nov',
			'11' => 'Dec' };

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time-3600*24);
$year += 1900;
my $yestday = sprintf("%04d-%02d-%02d", $year, $mon + 1, $mday);
if ( $wday == 6 ){
	$wday = 0;
} else {
	$wday++;
}

#print $mymonth->{$mon} . "\n";
#print "$year $wday\n";

if ( $wday == 0 ) {
	@filelist = ('messages.1' , 'messages' );
} else {
	@filelist = ('messages');
}

foreach (@filelist) {
open $datafile, "$source/$_" or die "Can not open $source/$_, $!\n";
foreach (<$datafile>){
	if (/^($mymonth->{$mon}) *($mday) *.* *($year) *(\w+) *.*:-DevIP=(\d+\.\d+\.\d+\.\d+) *.*/){
		$devip = ${5};
		push @data_match_info, $_;
		next;
	}
}
close $datafile;
}

open $data_save_info, ">/home/${user}/${yestday}_${devip}.log" or die "Can not save /home/${user}/${yestday}_${devip}.log, $!\n";
select $data_save_info;
foreach (@data_match_info) {
	print $_;
}
close $data_save_info;


my ($login,$pass,$uid,$gid) = getpwnam($user);

if ( -r "/home/${user}/${yestday}_${devip}.log" && defined $uid && defined $gid ) {
	chown "$uid", "$gid", "/home/hugo/${yestday}_${devip}.log";
} else { 
	warn "Chown $user failure\n";
}
