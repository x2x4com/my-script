aaaaaaaaaaaaaaaaaaaaaaaaaaaaa
#**********************************************************
#
# Script Name:   monitor_agent
# Script Author: jacky.xu@serversupport.cn
# Created Date:  2008-11-11
# Function desc:  It's Jacky Perl Monitor System Agent
#                 Start Agent by config_files
#                 This is agent
#
# Script Usage:  monitor_agent -c config_file
#
# Script Needs:  None
#
#**********************************************************

use strict;
use File::Basename;
use IO::Socket;
use POSIX qw(WNOHANG);

my $script_name = basename $0;
my $script_dir = dirname $0;
my $config = {};
my ($config_file,$service_config,$global_config,$service_list);

sub useage {
    die "  Useage : $script_name -c config\n";
}

if ( (@ARGV == 2) && ($ARGV[0] eq '-c') ){
    $config_file = $ARGV[1];
} else {
    useage();
}

open CONFIG, "<$config_file" or die "Can not open config file, $!\n";
foreach (<CONFIG>) {
    next if (/^#.*/);
    chomp $_;
    if (/^\[(Global)\]/) {
        $global_config = 1;
        next;
    } elsif (/^\[(Service)(\d+)\]/){
        $global_config = 0;
        $service_config = $2;
        next;
    } elsif (/^.*=.*/) {
        if ( $global_config == 1 ) {
            my ($key,$value) = split /\s*=\s*/, $_;
            $config->{"global"}->{$key} = $value;
            #print "global->$key = $value\n";
            next;
        } elsif ( $service_config =~ /(\d+)/) {
            my ($key,$value) = split / *= */, $_;
            $config->{"service$1"}->{$key}=$value;
            #print "service$1->$key = " . $config->{"service$1"}->{"$key"}."\n";
            next;
        }
    } else { next;}
}

#print "$service_config\n";

## Config check ##
die "Config check error in Global, logserver_ip\n" unless ($config->{"global"}->{"logserver_ip"} =~ /^([1-9]|[1-9]\d|1\d{2}|2[01]\d|22[0-3])(\.(\d|[1-9]\d|1\d{2}|2[0-4]\d|25[0-5])){3}$/);
die "Config check error in Global, logserver_port\n" unless ( ($config->{"global"}->{"logserver_port"} < 65536) && ($config->{"global"}->{"logserver_port"} > 0) );
die "Config check error in Global, listen_port\n" unless ( ($config->{"global"}->{"listen_port"} < 65536) && ($config->{"global"}->{"listen_port"} > 0) );


##################

## Init ##
my $client_answer;
$|=1;
##########

## Action Sub ##
my $command_action = sub {
    my @command_return;
    eval {
    @command_return = `$_[0]` #|| die "$!\n"
    };
    if ($@) {
        return $@;
    } else {
        return @command_return;
    }
};
################

## Reaped Child ##
$SIG{'CHLD'} = sub {
     while((my $pid = waitpid(-1, WNOHANG)) >0) {
          print "Reaped child $pid\n";
      }
};
##################

## Define Socket ##
my $server = IO::Socket::INET->new( LocalPort   => $config->{global}->{listen_port},
                                Type        => SOCK_STREAM,
                                Reuse       => 1,
                                Proto       => 'tcp',
                                Timeout     => $config->{global}->{timeout},
                                Listen      => 20)
    or die "Couldn't be a tcp server on port $config->{global}->{listen_port}: $!\n";
###################

## Main Loop ##
#warn "Starting Server on Port $config->{global}->{listen_port}\n";
while (1) {
    ## Accept user connect ##
    next unless my $client = $server->accept;
    ## Fork process ##
    defined (my $pid = fork) or die "Can't fork: $!\n";

    if ($pid ==0) {
        ## Get Client IP ##
        my $peer = gethostbyaddr($client->peeraddr, AF_INET) || $client->peerhost;
        ## Get Client Port ##
        my $port = $client->peerport;
        warn "Connection from $peer:$port\n";
        ## Flush Socket ##
        $client->autoflush(1);
        ## Send to Client ##
        print $client "service_name:\n";
        ## Get answer from socket ##
        chomp ($client_answer = <$client>);
        ## Test Username ##
		my $valid_service;
		for (my $i=1;$i<$service_config+1;$i++) {
			my $i_f = sprintf("%02d",$i);
        	if ( "$client_answer" eq crypt($config->{"service$i_f"}->{"service_name"},$client_answer) ) {
				$service_list = $i_f;
				$valid_service = 1;
				last;
			}
		}
			if ($valid_service == 1){
            	print $client "keys:\n";
            	#print "user = $client_answer\n";
            	## Get password from socket ##
            	chomp ($client_answer = <$client>);
            	#print "password = $client_answer\n";
				#print $config->{"service$service_list"}->{"communication_key"}."\n";
                	if ( "$client_answer" eq crypt($config->{"service$service_list"}->{"communication_key"},$client_answer) ) {
                    	print $client "ok,go ahead\n";
                    	chomp ($client_answer = <$client>);
                    	my @command_status = $command_action->($client_answer) if (defined $client_answer);
                    	print $client "@command_status\n";
                    	#$client->shutdown(1);
                    	close $client;
                    	warn "Connection from $peer:$port finished\n";
                    	exit 0;
                	} else {
                    	print $client "Bad Keys\n";
                    	warn "Bad Auth Keys, Drop it\n";
                    	close $client;
                    	exit 0;
                	}
        	} else {
            	print $client "Bad service_name\n";
            	warn "Bad service_name, Drop it\n";
            	close $client;
            	exit 0;
        	}
    	}
}

close ($server);
#################
