#!/usr/bin/perl

#**********************************************************
#
# Script Name:   log_center
# Script Author: jacky.xu@serversupport.cn
# Created Date:  2008-10-23
# Function desc:  It's Jacky Perl Monitor System Log Center
#                 Started by monitor_center
#                
#
# Script Usage:  log_center port timeout log_save_dir log_save_name
#
# Script Needs:  None
#
#**********************************************************

use strict;
use POSIX qw(strftime);
use IO::Socket;
use POSIX qw(WNOHANG);


die "Parameter Error\n" unless ( @ARGV == 4 );
$| = 1;

## defind time format ##
my $time_format = sub { my $time_now = POSIX::strftime("\[%Y-%m-%d %H:%M:%S\]", localtime(time));return $time_now;};
my $today = POSIX::strftime("%Y-%m-%d", localtime(time));
## defind time format over ##

my $client_answer;

my ($server_port,$timeout,$log_dir,$log_file) = @ARGV;
open "LOGFILE", ">>$log_dir/${today}_${log_file}" or die "Can't write $log_dir/${today}_${log_file}, $!\n";

$SIG{'CHLD'} = sub {
    while((my $pid = waitpid(-1, WNOHANG)) >0) {
        print LOGFILE "" . $time_format->() . " Reaped child $pid\n";
    }
};


my $server = IO::Socket::INET->new( LocalPort   => $server_port,
                                    Type        => SOCK_STREAM,
                                    Reuse       => 1,
                                    Proto       => 'tcp',
                                    Timeout     => $timeout,
                                    Listen      => 20)
	or die "Couldn't be a tcp server on port $server_port: $!\n";
print LOGFILE "" . $time_format->() . " Start logserver\n";
while (1) {
    ## Accept user connect ##
    next unless ( my $client = $server->accept );
    ## Fork process ##
    defined (my $pid = fork) or die "Can't fork: $!\n";

    if ($pid ==0) {
        my $peer = gethostbyaddr($client->peeraddr, AF_INET) || $client->peerhost;
        ## Get Client Port ##
        my $port = $client->peerport;
        print LOGFILE "" . $time_format->() . " Connection from $peer:$port\n";
        ## Flush Socket ##
        $client->autoflush(1);
		$SIG{ALRM} = sub { die "Timeout\n"};
		eval {
		alarm ($timeout);
        chomp ($client_answer = <$client>);
        close $client;
		alarm (0);
		};
		if ( $@ =~ /Timeout/ ) {
		close $client;
		print LOGFILE "" . $time_format->() . " Connection of $peer:$port timeout\n";
		} else {
        	if ( $client_answer =~ /^\[Client Log\]/ ) {
            	print LOGFILE "" . $time_format->() . " $client_answer\n";
        	}
		}
		exit 0;
    }
}
close LOGFILE;
close $server;
