#!/usr/bin/perl


use strict;
use Thread;
#use POSIX qw(strftime);
use Getopt::Std;
use LWP::UserAgent;
use HTTP::Request::Common;
use Time::HiRes qw(time);

my %opts;
getopts('ht:u:c:f:r:', \%opts) or help(1);

if ($opts{h}) { help(0) }
my $count = $opts{c} || help(1);
my $url = $opts{u};
my $url_return = $opts{r};
my $url_file = $opts{f};
my $time = $opts{t} || help(1);

my %urls;
$urls{'url'} = [];
$urls{'return'} = [];

if (-f $url_file){ 
	open URLS, "$url_file" or die "Can not open $url_file, $!\n";
	my $start = 0;
	foreach my $tmp (<URLS>) {
		chomp $tmp;
		if ( $tmp =~ /^(http:\/\/.*)\|\|(.*)$/ ) {
			$urls{'url'}->[$start]  = $1;
			$urls{'return'}->[$start] = $2;
			$start++;
			next;
		}
	}
} elsif ( ($url =~ /^http:\/\//) && (defined $url_return) ) {
	$urls{'url'}->[0] = $url;
	$urls{'return'}->[0] = $url_return;
} else {
	help(1);
}

#print @{$urls{'url'}} . "\n";


sub help {
    my $code = shift;
    my $out = <<'_AAAAA_';
Usage: web-bench.pl [options] 
Options:
    -c <client number>	How many theard you want to use
    -h							Print this help.
    -t <time>				Running time in seconds.
    -u <url>					http://url
    -r <server return>	servers reutrn key, must after -u option
    -f <url file>				path:file
    
Examples:
    web-bench.pl -c 10 -t 60 -u http://www.online.sh.cn
    web-bench.pl -c 10 -t 60 -f urllist.txt
    #cat urllist.txt
    http://www.online.sh.cn||server return key
    http://www.sina.com.cn||server return key

_AAAAA_
    if ($code == 0) { print $out } else { warn $out }
    exit($code);
}

my $ua = new LWP::UserAgent(keep_alive => 1, cookie_jar =>{} );

sub to_get {
	my ($url,$return) = @_;
	my $response = $ua->request( 	GET $url,
									Referer => $url,
									User_Agent => 'OTHERS',
									Content_Type => 'text/xml; charset=gb2312');

	my $return_code = 0;
	if ($response->is_success) {
		foreach ($response->content) {
			if (/$return/) {
				$return_code = 1;
				last;
			}
		}
	} else {
		$return_code = 0
	}
	return $return_code;
}

#for (my $t = 0;$t<@{$urls{'url'}};$t++) {
#	print $t  .  "    ";
#	print $urls{'url'}->[$t] . "     ";
#	print $urls{'return'}->[$t] . "\n";
#	my $time_before = time;
#	to_get($urls{'url'}->[$t],$urls{'return'}->[$t]);
#	my $pass_time = time - $time_before;
#	print $pass_time . "\n";
#}

sub start_vist {
	my $thread = shift;
	eval {
		local $SIG{ALRM} = sub { die "timeover\n";};
		alarm ($time);
		while (1) {
			my $r = int (rand @{$urls{'url'}});
			my $time_before = time;
			my $code = to_get($urls{'url'}->[$r],$urls{'return'}->[$r]);
			my $pass_time = time - $time_before;
			print $thread . "   ";
			print $urls{'url'}->[$r] . "    " . "$code    ";
			print $pass_time . "\n";
		}
		alarm (0);
	};
	die "$time up\n" if ( $@ =~ /timeout/ );
}


## Start Thread ##
my @t;
for (my $i=0;$i<$count;$i++){
	$t[$i] = Thread->new(\&start_vist,$i);
}
for (my $i=0;$i<$count;$i++){
    $t[$i]->join();
}
## Start Thread over ##
