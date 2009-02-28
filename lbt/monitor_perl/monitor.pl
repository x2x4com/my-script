#!/usr/bin/perl -w
#**********************************************************
#
# Script Name:   monitor.pl
# Script Author: jacky.xu@serversupport.cn
# Created Date:  2008-8-25
# Function desc: 1. monitor defined port 
#		 2. if service crash, auto send mail & sms(use sendmail.pl and sms.pl)
#
# Script Usage:  monitor.pl
#
#**********************************************************

use strict;
use File::Basename;
use POSIX qw/strftime/;
use IO::Socket::INET;
use Net::Ping;

## conf ##
my (@services,$myproto,$myip,$myport,$mytype,$timenow,$socket,$socket_test,$socket_answer,$mylogopen);

@services = ( 'tcp:192.168.1.15:22221',
	      'tcp:192.168.1.10:65534',
	      'tcp:192.168.1.10:1521',
	      'tcp:192.168.1.1:22',
	      'tcp:192.168.1.18:80',
	      'tcp:192.168.1.41:80');

my $sleep_time = '30';
my $mylogfile = 'log/monitor.log';
my $sms_prog = './sms.pl';
my $mail_prog = './sendmail.pl';
my $sms_use = 1;  ## 1 is use
my $sms_to = '13918299350,13917133160';
my $mail_use = 1;  ## 1 is use
my $mail_send_to = 'x2x4com@gmail.com,jacky.xu@serversupport.cn';
my $mail_send_to_cc = '';
my $mail_from = 'Perl System Monitor';
my $mail_server = 'mail.livebytouch.com';
my $mail_user = 'jacky.xu@livebytouch.com';
my $mail_pass = '';


## testing config ##
unless ( $sms_use =~ /^(1|0)$/){
  die "[Error] Your \$sms_use value is $sms_use, not 1 or 0\n";
}
if ( $sms_use == 1) {
if (! -r $sms_prog){
  die "[Error] $sms_prog not find or can't read\n";
} elsif (! -x $sms_prog){
  die "[Error] $sms_prog can't execute\n";
}
}

unless ( $mail_use =~ /^(1|0)$/){
  die "[Error] Your \$mail_use value is $mail_use, not 1 or 0\n";
}
if ( $mail_use == 1 ) {
if (! -r $mail_prog){
  die "[Error] $mail_prog not find or can't read\n";
} elsif (! -x $mail_prog){
  die "[Error] $mail_prog can't execute\n";
}
}

my $mylogdir = dirname $mylogfile;
my $myscriptdir = basename $0;
if (! -d $mylogdir){
  print "[Warn] $mylogdir not find, auto create it\n";
  mkdir "log", 0755 or die "Can't mkdir log @ $myscriptdir: $!\n";
}

## logfile handle ##
open $mylogopen, ">>$mylogfile" or die "Can't write $mylogfile, $!\n";

## sub ##
sub socket_tcp_test {
$socket_test = 0;
$socket = IO::Socket::INET->new(PeerAddr => "$myip",
				PeerPort => "$myport",
				Proto => "$myproto",
				Type => SOCK_STREAM
				Timeout => 5) or $socket_test = 2;
if ($socket_test == 2) {
  return 0;  ## 0 is failing
} else {
  print $socket "Perl Monitor\n";
  #$socket_answer =<$socket>;
  #print "socket_answer = $socket_answer\n";
  close($socket);
  return 1;   ##  1 is ok
}
}

## main loop##
while (1) {
#select $mylogopen;
foreach (@services) {
    $timenow = strftime("%y/%m/%d-%H:%M:%S", localtime);  ## get system time like yy/mm/dd-HH:MM:SS
    ($myproto,$myip,$myport) = split /:/,$_;		  ## split proto ipadress/domain and port
    if (! defined $myproto or ! defined $myip or ! defined $myport){
       print "find undefined variable, jump to next line\n";
       next;
    }
    							  ## print "$timenow : $myip  $myport  $myproto\n";
    if ( $myproto eq "tcp" ){
        $socket_test = &socket_tcp_test;		  ## test tcp port
        # print "$socket_test\n";
    } elsif ( $myproto eq "udp") {
	print "$myproto->$myip:$myport => Sorry, udp is not support temporary\n";
	next;
    } else { 
	close ($mylogopen);
	die "[Error] Proto $myproto not support\n";
    }
    if ($socket_test){
        print "\[$timenow\] Server:$myip:$myport => ok\n";
    } else {
	my $p = Net::Ping->new();
	if ( $p->ping($myip, 2) ) {
	  print "\[$timenow\] Ping Server:$myip => ok but Port:$myport => die\n";
	  print "\[$timenow\] Starting send mail\n";
	  if ( $mail_use == 1 ){
	    my $mailreturn = system "$mail_prog","server:$mail_server","user:$mail_user","pass:$mail_pass","to:$mail_send_to","from:$mail_from","sub:\[System Monitor Alert\] Server:$myip Problem","message:\[$timenow\] Ping Server:$myip => ok but Port:$myport => die";
            if ( $mailreturn == 0 ){
	      print "\[$timenow\] Sending ok\n";
	    } else {
              print "Sendmail looks failure, it return $mailreturn\n";
	    }
	  }
       	  if ( $sms_use == 1) {
	    print "\[$timenow\] Starting send sms\n";
	    my $smsreturn = system "$sms_prog","$sms_to","\[$timenow\] Ping Server:$myip => ok but Port:$myport => die";
          }
        } else {
	  print "\[$timenow\] Ping $myip => die and $myport => die\n";
	  if ( $mail_use == 1 ){
	    print "\[$timenow\] Starting send mail\n";
	    my $mailreturn = system "$mail_prog","server:$mail_server","user:$mail_user","pass:$mail_pass","to:$mail_send_to","from:$mail_from","sub:\[System Monitor Alert\] Server:$myip Problem","message:\[$timenow\] Ping Server:$myip => die and Port:$myport => die";
	    if ( $mailreturn == 0 ){
	      print "\[$timenow\] Sending ok\n";
	    } else {
	      print "\[$timenow\] Sendmail looks failure, it return $mailreturn\n";
	    }
	  }
	  if ( $sms_use == 1) {
            print "\[$timenow\] Starting send sms\n";
            my $smsreturn = system "$sms_prog","$sms_to","\[$timenow\] Ping Server:$myip => die and Port:$myport => die";
          }
	}
	$p->close();
    }
}
#close ($mylogopen);
sleep ($sleep_time);
}
