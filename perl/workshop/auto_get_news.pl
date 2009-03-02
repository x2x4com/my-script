#!/usr/bin/perl

use strict;
#use File::Basename;
#use POSIX qw(strftime);
#use Thread;
use LWP::UserAgent;
use HTTP::Request::Common;

my @website;

$website[0]={ 'url' => 'http://lady.hsw.cn/node_3592.htm',
						'commons' => 'lady.hsw.cn 彩妆频道',
						'base' => 'http://lady.hsw.cn/' };

$website[1]={ 'url' => 'http://lady.hsw.cn/node_3563.htm',
						'commons' => 'lady.hsw.cn 护肤频道' ,
						'base' => 'http://lady.hsw.cn/' };
						

my $ua = new LWP::UserAgent(	keep_alive => 1,
												User_Agent => 'OTHERS',
												Content_Type => 'text/xml; charset=gb2312' );

sub to_get {
	my ($count) = @_;
	my $response = $ua->request( 	GET $website[$count]->{url},
									Referer => $website[$count]->{url});

	print "正在访问" . $website[$count]->{commons} ."\n";
	if ($response->is_success) {
		#print "success, server return: " . $response->code . "\n";
		$website[$count]->{content} = [] ;
		(@{$website[$count]->{content} } )= split /\n/,$response->content;
	} else {
		$website[$count]->{content} = $response->as_string;
		$website[$count]->{failed} = 1;
	}
}

sub get_news {
	my ($url)= @_;
	print "get $url\n";
	my $response = $ua->request( GET $url, Referer => $url );
	if ($response->is_success) {
		
	} else {
		
	}
}

for ( my $i=0;$i<@website;$i++ ) {
	to_get($i);
	if ( defined $website[$i]->{failed} ) {
		print "访问" . $website[$i]->{commons} . "失败，原因为: \n" . $website[$i]->{content} ."\n";
		next;
	}
	print "访问" . $website[$i]->{commons} . "结果为:\n" ;#. $website[$i]->{content} ."\n";
	#print @{$website[$i]->{content} } . "\n";
	$website[$i]->{match_url} = [];
	foreach my $tmp_content ( @{$website[$i]->{content} } ) {
		#print $tmp_content . "\n";
		#sleep 1;
		if ( $tmp_content =~ /<\!\-\-begin\s*\d+\-\d+\-\d+\-\->(.*)<\!\-\-end\s*\d+\-\d+\-\d+\-\->/ ) {
			my $match = $1;
			if ( $match =~ /<a\s*href=\d+\-\d+\/\d+\/content_\d+\.htm>.*/ ) {
				@{$website[$i]->{match_url}} = split /<br>/,$match;
				next;
			}
		}	
	}
	#print @{$website[$i]->{match_url}}. "\n";
	for ( my $ii=0;$ii<@{ $website[$i]->{match_url} };$ii++) {
		if ( $website[$i]->{match_url}->[$ii] =~ /^<a\s*href=(\d+\-\d+\/\d+\/content_\d+\.htm)>(.*)<\/a>$/ ) {
			#print "$2 url is " . $website[$i]->{base} . "$1\n";
			$website[$i]->{match_url}->[$ii] = $website[$i]->{base} . $1;
			#print $website[$i]->{match_url}->[$ii]  . "\n";
			$website[$i]->{"match_url_info_$ii"} = $2;
 		}
	}
	#print $website[$i]->{match_url}->[30] . $website[$i]->{match_url_info_30} . "\n";
	
	my $user_input;
	my $loop = 1;
	while ($loop) {
	print "请选择你要下载的新闻:\n";
	for ( my $ii=0;$ii<(@{ $website[$i]->{match_url} }-1);$ii++) {
		print "\[$ii\] " . $website[$i]->{"match_url_info_$ii"}  ."\n";
	}
	print "请输入新闻编号,下载全部请输入a，退出请输入q \[0~" . (@{ $website[$i]->{match_url} } -2) . "\]: ";
	undef $user_input;
	$user_input = <STDIN>;
	chomp $user_input;
	#print "$user_input\n";
	if ( $user_input =~ /\d+/ && ($user_input >= 0) && ($user_input < (@{ $website[$i]->{match_url} } -1)) ) {
		print "选择下载新闻: " . $website[$i]->{"match_url_info_$user_input"} . "\n";
		get_news($website[$i]->{match_url}->[$user_input]);
	} elsif ( $user_input =~ /[all|a|ALL|A]/ ) {
		print "download all\n";
	} elsif ( $user_input =~ /[quit|q|QUIT|Q]/ ) {
		$loop = 0;
	}
	}
}

