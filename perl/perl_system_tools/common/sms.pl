#!/usr/bin/perl 
#**********************************************************
#
# Script Name:   sms.pl
# Script Author: jacky.xu@serversupport.cn
# Created Date:  2008-8-20
# Function desc: 1. send sms via fetion rebot
#
# Script Usage:  sms.pl cellphone[,cellphone,cellphone ...] messages
#
# 
#**********************************************************

use strict;
use Encode qw/from_to/;
use IO::Socket::INET;
use POSIX qw/strftime/;
use File::Basename;

my $fetion_host = '192.168.1.1';
my $fetion_port = "40000";
my $timenow = strftime("%m/%d-%H:%M:%S", localtime);
my $scriptbase = basename $0;

my (@sendto, $smsbody, $socket, $sendout);

if (@ARGV lt 1){
	die "Error! no parameter find\nUseage: $scriptbase cellphone,cllphone message\n";
}

if ( $ARGV[0] =~ /^\d+(,\d+)*$/){
	@sendto = split ( /,/, $ARGV[0] );
	shift;
} else {
	die "Bad cellphone format, $ARGV[0]\n";
}


if (defined @ARGV){
	for (my $i=0;$i<@ARGV;$i++){
		$smsbody .= " $ARGV[$i]";
	}
	#$smsbody = "\[$timenow\]$smsbody";
} else {
	print "Please input Message body\n";
	chomp($smsbody = <STDIN>);  
	#$smsbody = "\[$timenow\] $smsbody";
}


$socket = IO::Socket::INET->new( PeerAddr => $fetion_host,
				PeerPort => $fetion_port,
				Proto => "udp",
				Type => SOCK_DGRAM);
	#or die "Couldn't connect to $fetion_host:$fetion_port, $!\n";

for (my $i=0;$i<@sendto;$i++){
	$sendout = "sms $sendto[$i] $smsbody"; 
	from_to($sendout,"gb2312","utf8");
	print $socket $sendout;
	#print "$sendout ... done\n";
}
close ($socket);
exit 0
