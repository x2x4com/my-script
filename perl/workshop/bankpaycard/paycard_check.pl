#!/usr/bin/perl
#**********************************************************
#
# Script Name:   paycard_check.pl;
# Script Author: jacky.xu@livebytouch.com
# Created Date:  2009-01-24
# Function desc:  check banks paycard file
#
# Script Usage:  paycard_check.pl -c config_file
#
# Script Needs:  sendmail.pl (sendmail) if open use_mail
#
#**********************************************************

use strict;
use warnings;
use File::Basename;
use POSIX qw(strftime);

use Getopt::Std;

my $script_name = basename $0;
my $script_dir = dirname $0;
my $yestday = POSIX::strftime("%Y%m%d", localtime(time - 3600 * 24));
my $today = POSIX::strftime("%Y%m%d", localtime(time));
#print "$yestday\n$today\n";

my %opts;
getopts('hc:', \%opts) or useage(1);
my $config_file = $opts{c} ;
useage(99) unless ( defined $config_file );


sub useage {
	my $code = shift;
	my $out =  "  Useage : $script_name -c config\n";
	print $out;
	exit $code;
}

my ($global_config,$service_config,@bank_list);
my $config = {};

open CONFIG, "<$config_file" or die "Can not open config file, $!\n";
foreach (<CONFIG>) {
	next if (/^#.*/);
	chomp $_;
	if (/^\[(global)\]/) {
		$global_config = 1;
		next;
	} elsif (/^\[(bank)(\d+)\]/){
		$global_config = 0;
		#print "$2\n";
		$service_config = $2;
		push @bank_list, "bank$2";
		next;
	} elsif (/^.*=.*/) {
		#print "$1    ,     $2\n";
		my ($key,$value) = split /\s*=\s*/, $_;
		#my ($key,$value) = ($1,$2);
		if ( $global_config == 1 ) {
			$config->{"global"}->{$key} = $value;
			#print "\$config->global->$key = $value\n";
			next;
		} elsif ( $service_config =~ /(\d+)/) {
			$config->{"bank$1"}->{$key}=$value;
			#print "\$config->bank$1->$key = $value\n";
			next;
		}
	} else { next;}
}

#print "@bank_list\n";
sub email {
	my ($sub,$message) = @_;
	my @args = ( $config->{global}->{mail_proc} , "server:" . $config->{global}->{mail_server} ,  "user:" .  $config->{global}->{mail_user} , "pass:" .  $config->{global}->{mail_user_pass} , "to:" . $config->{global}->{mail_to} , "cc:" . $config->{global}->{mail_cc} , "from:" . $config->{global}->{mail_from} , "sub:" . $sub , "message:" . $message);
	if ( -x $config->{global}->{mail_proc} ) {
		system(@args) == 0 or warn "Sendmail failed: $? \n" ; 
		#print "@args\n";
	}
}

foreach my $bank ( @bank_list ) {
	my $cf;
	my $bankfile = $config->{$bank}->{path} . $config->{$bank}->{file_prefix} . $yestday .  '.' . $config->{$bank}->{file_suffix};
	my $return = $config->{$bank}->{bank_return};
	my @line;
	#print "$bankfile\n";
	if ( ! open $cf,$bankfile) {
		warn "Can not open $bankfile\n" ;
		next;
	}
	foreach (<$cf>) {
		chomp;
		#print "$_\n";
		@line = split /\|/;
		unless ($line[$return] eq "*") {
			if ($config->{global}->{use_mail}) {
				use Encode;
				my $sub = $today . $config->{$bank}->{commons} . '资金划拨失败';
				my $message = '<Font size=\'2\'>' . $config->{$bank}->{commons} . '资金划拨失败' . '<BR>' . '记录内容为: <BR> ' .  "$_"  . '<BR>Paycard 文件: <BR> ' . "$bankfile" . '</font>'; 
				$sub = encode("gb2312",decode("utf-8",$sub));
				$message = encode("gb2312",decode("utf-8",$message));
				email($sub,$message);
			}
		}
	}
}
	
