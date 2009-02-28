#!/usr/bin/perl

use strict;
use File::Basename;
use POSIX qw/strftime/;
use IO::Socket::INET;

## configure ##
my $scriptbase = basename $0;
my (@services,$myproto,$myurl,$myip,$myport,$socket,$mylogopen,@socket_answer,$timenow,$website_status,$socket_test,$mykeys,$findkeys,%mytarget_website);

@services = ( '192.168.10.4/:80:x6868',
		'192.168.10.5/:80:x9898');
%mytarget_website = ( paybyfinger => "192.168.10.4",
                        livebytouch => "192.168.10.5");

my $mail = { server => 'mail.livebytouch.com',
	  user => 'jacky.xu@livebytouch.com',
	  pass => '',
	  to => 'arthur.wang@livebytouch.com,zhetao.su@livebytouch.com,hugo.lu@livebytouch.com',
	  cc => 'jacky.xu@livebytouch.com',
	  from => 'Jacky Xu' };

#foreach (keys %{$mail}){
#	print "$_ value is $mail->{$_}\n";
#}

my $sleep_time = '30';
my $time_out = '30';
my $mylogdir = "./log";

if ( ! -d $mylogdir ){
  print "[Warn] $mylogdir not find, auto create it\n";
  mkdir "log", 0755 or die "Can't mkdir log @ $scriptbase: $!\n";
}



sub socket_tcp_test {
  eval{
  $socket = IO::Socket::INET->new(PeerAddr => "$myip",
				  PeerPort => "$myport",
				  Proto => "tcp",
				  Type => SOCK_STREAM,
				  Timeout => "$time_out")
			or die "$myip:$myport die\n";
  };
  if ($@ =~ /$myip:$myport die/){
    return 0; ## 0 is die
  } else {
    $SIG{ALRM} = \&time_out;
    print $socket "GET http://$myurl\n";
    eval{
      alarm ($time_out);
      @socket_answer = <$socket>;
      close ($socket);
      alarm (0);
    };
    sub time_out { die "Timeout\n" };
    if ( $@ =~ /Timeout/ ) {
      close ($socket);
      return 0;
    } else {
      foreach (@socket_answer){
	$findkeys = 0;
        if (/$mykeys/){
	 #print $_ . "\n";
          $findkeys = 1;
	  last;
        } else {
 	 #print $_ . "\n";
          next;
        }
      }
      if ($findkeys){
        return 1;
      } else {
        return 0;
      }
    }
  }
}



sub website_restart {
	foreach (keys %mytarget_website) {
		#print "$mytarget_website{$_}\n";
		if ( $myip eq $mytarget_website{$_} ){
			$mail->{subject} = "\[Warn\] $_ is dead";
			$mail->{message} = "\[$timenow\] $_ is die, restart it now";
			print "$mail->{message}\n";
			system "/data/tomcat/tomcat.sh","$_","stop";
			sleep (10);
			system "/data/tomcat/tomcat.sh","$_","start";
			&send_mail;
			last;
		}
		next;
	}
}

sub send_mail {
	my $my_script_dir = dirname $0;
	if ( -r "$my_script_dir/sendmail.pl" && -x "$my_script_dir/sendmail.pl" ){
	system "$my_script_dir/sendmail.pl","server:$mail->{server}","user:$mail->{user}","pass:$mail->{pass}","to:$mail->{to}","from:$mail->{from}","sub:$mail->{subject}","message:$mail->{message}";
	}
}

## main loop ##
while (1) {
  ## logfile handle ##
  my $today = strftime("%y-%m-%d", localtime);  ## get system time like yy-mm-dd
  my $mylogfile = "$mylogdir/${scriptbase}_$today.log";
  open $mylogopen, ">>$mylogfile" or warn "Can't write $mylogfile, $!\n";
  select $mylogopen; ## open logfile ##
  ## do monitor ##
  foreach (@services) {
    $timenow = strftime("%y/%m/%d-%H:%M:%S", localtime);  ## get system time like yy/mm/dd-HH:MM:SS
    ($myurl,$myport,$mykeys) = split /:/,$_;		  ## split ipadress/domain and port
    if ( $myurl =~ /(.*)\/(.*)*/ ){
      #print "$1\n";
      $myip = $1;
    }
    if (! defined $myip or ! defined $myport or ! defined $mykeys){
      print "find undefined variable, jump to next line\n";
      next;
    }
    #print "$myip $myport $mykeys $myurl\n";
    $website_status = &socket_tcp_test;
    if ($website_status){
      #print "\[$timenow\] $myip:$myport is ok and service is ok\n";
      sleep 1;
    } else {
      &website_restart;
    }
  }
  close $mylogopen;
  sleep ($sleep_time);
}
