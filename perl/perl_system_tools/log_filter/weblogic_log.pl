#!/usr/bin/perl

#use POSIX qw(strftime);

if (! defined $ARGV[0] ){
	die "useage : command filename\n";
}
my $datafile,@data_match_info,@data_match_error,$data_save_info,$data_save_error;
my $source = $ARGV[0];
#my $yestday = POSIX::strftime("%Y-%m-%d", localtime(time-3600*24));
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time-3600*24);
my $yestday = sprintf("%04d-%d-%d", $year + 1900, $mon + 1, $mday);
my $date_error = 0;

open $datafile, $source or die "Can not open $source, $!\n";
foreach (<$datafile>){
	#print "$yestday\n";
	if (/^####<($yestday).*<(Info|Debug)>.*/){
		$date_error = 0;
		#print "match info\n";
		push @data_match_info, $_;
		next;
	} elsif (/^####<($yestday).*<(Error|Warning)>.*/){
		push @data_match_error, $_;
		$date_error = 1;
		next;
	} elsif (/^####/){
		$date_error = 0;
		next;
	} elsif ($date_error) {
		push @data_match_error, $_;
		next;
	}
}
close $datafile;

open $data_save_info, ">${yestday}_info.txt" or die "Can not save ${yestday}_info.txt, $!\n";
select $data_save_info;
foreach (@data_match_info) {
	print $_;
}
close $data_save_info;

open $data_save_error, ">${yestday}_error.txt" or die "Can not save ${yestday}_error.txt, $!\n";
select $data_save_error;
foreach (@data_match_error) {
	print $_;
}
close $data_save_error;
 	
