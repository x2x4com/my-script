#!/usr/bin/perl


use strict;
use LWP::UserAgent;
use HTTP::Request::Common;

sub usage {
	die "Usage: script visit_count sleep_time(sec) \"http://yourdomain\"\n";
}

usage() if ( @ARGV < 3 ) ;
usage() unless ( $ARGV[0] =~ /\d+/ );
usage() unless ( $ARGV[1] =~ /\d+/ );
usage() unless ( $ARGV[2] =~ /^http:\/\// );

my $count = $ARGV[0];
my $sleep_time = $ARGV[1];
my $url = $ARGV[2];

my $ua = new LWP::UserAgent(keep_alive => 1, cookie_jar =>{} );

sub to_get {
	my ($count,$url) = @_;
	my $response = $ua->request( 	GET $url,
									Referer => $url,
									User_Agent => 'OTHERS',
									Content_Type => 'text/xml; charset=gb2312');

	print "Visit count: $count ... ";
	if ($response->is_success) {
		print "success, server return: " . $response->code . "\n";
		#print $response->content . "\n";
				my $ax = 0;
		foreach ($response->content) {
			if (/\n/) {
			print $ax . "\n";
			$ax++;
			}
		}
	} else {
		print "failed, server return: \n" . $response->as_string . "\n";
	}
}



for ( my $i=0;$i<$count;$i++ ) {
	to_get($i,$url);
	sleep $sleep_time;
}
