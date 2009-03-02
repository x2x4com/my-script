#!/usr/bin/perl

#**********************************************************
#
# Script Name:   ecustmde_play
# Script Author: jacky.xu@serversupport.cn
# Created Date:  2008-11-12
# Function desc:  Auto play ecustmde's videos
#
# Script Usage:  ecustmde_play -c conf_file
#
# Script Needs:  None
#
#**********************************************************


use strict;
use IO::Socket;
use POSIX qw(strftime);
use Thread;
use File::Basename;


my $script_name = basename $0;
my $script_dir = dirname $0;
my $config = {};
my ($config_file,$service_config,$global_config);

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
    } elsif (/^\[(Course)(\d+)\]/){
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
            $config->{"course$1"}->{$key}=$value;
            #print "service$1->$key = $value\n";
            next;
        }
    } else { next;}
}

## Config check ##


##################


## defind time format ##
my $time_format = sub { my $time_now = POSIX::strftime("\[%Y-%m-%d %H:%M:%S\]", localtime(time));return $time_now;};
my $yymmdd = sub { my $time_now = POSIX::strftime("%Y-%m-%d", localtime(time));return $time_now;};
## defind time format over ##

my @socket_answer;
my $socket = IO::Socket::INET->new(PeerAddr => "211.157.9.22",
									PeerPort => "80",
									Proto => 'tcp',
									Type => SOCK_STREAM,
									Timeout => "60") or die "Can not connect 211.157.9.22:80, $!\n";

$SIG{ALRM} = \&time_out;
print $socket "GET http://savagexu:sandy5xu@211.157.9.22/Student/NetClassroom/index.asp\n" or die "Can not send data to 211.157.9.22:80, $!\n";
eval{
	alarm (60);
	@socket_answer = <$socket>;
	close ($socket);
	alarm (0);
};
sub time_out { die "Timeout\n" };
if ($@ =~ /^Timeout/) {
	close ($socket);
	warn "211.157.9.22:80 waitting answer timeout\n";
} else {
	foreach my $tmp_0 (@socket_answer) {
		print "$tmp_0\n";
	}
};
