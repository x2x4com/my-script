#!/usr/bin/perl

#use POSIX qw(strftime);

if (! defined $ARGV[0] ){
	die "useage : command filename\n";
}

my $datafile,@data_match_info,@data_match_error,$data_save_info,$data_save_error;
my $source = $ARGV[0];
my ($log_name,$log_ext,$yestday) = split (/\./, "$source");
#print "$log_name,$log_ext,$yestday\n";
#sleep 60;
if (! defined $yestday){
	die "File name error, it's should be like server.log.2008-09-18\n";
}

## get system date, format like 2008-09-01 ##
#my $yestday = POSIX::strftime("%Y-%m-%d", localtime(time-3600*24));
#($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time-3600*24);
## get system date, format like 2008-9-1 ##
#my $yestday = sprintf("%04d-%d-%d", $year + 1900, $mon + 1, $mday);

my $date_error = 0;

open $datafile, $source or die "Can not open $source, $!\n";
foreach (<$datafile>){
	#print "$yestday\n";
	if (/^($yestday) \d+:\d+:\d+,\d+ *(INFO|DEBUG) \[.*$/){
		$date_error = 0;
		#print "match info\n";
		#push @data_match_info, $_;
		next;
	} elsif (/^($yestday) \d+:\d+:\d+,\d+ *(ERROR|WARN) \[.*$/){
		if (/^($yestday) \d+:\d+:\d+,\d+ *(ERROR|WARN) \[com\.lbt\.backend\.listener\.ListenerWorker\] IOException when process accept conection from bank,$/) {
			$date_error = 0;
			next;
		} elsif (/^($yestday) \d+:\d+:\d+,\d+ *(ERROR|WARN) .*: (cannot found this user|user is not valid)$/) {
			$date_error = 0;
			next;
		}
		push @data_match_error, $_;
		$date_error = 1;
		next;
	#} elsif (/^####/){
		#$date_error = 0;
		#next;
	} elsif ($date_error) {
		push @data_match_error, $_;
		next;
	}
}
close $datafile;

#open $data_save_info, ">${yestday}_info.txt" or die "Can not save ${yestday}_info.txt, $!\n";
#select $data_save_info;
#foreach (@data_match_info) {
#	print $_;
#}
#close $data_save_info;

open $data_save_error, ">${yestday}_jboss_error.txt" or die "Can not save ${yestday}_jboss_error.txt, $!\n";
select $data_save_error;
foreach (@data_match_error) {
	print $_;
}
close $data_save_error;
 	
