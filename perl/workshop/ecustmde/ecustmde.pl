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
#use File::Basename;
#use POSIX qw(strftime);
#use Thread;
use LWP::UserAgent;
use HTTP::Request::Common;
#use LWP::Debug qw(+);


my $username = 'savagexu';
my $password = 'abced';
my ($url,$post_url);

my $ua = new LWP::UserAgent(keep_alive => 1,cookie_jar => {} );

$ua->credentials('211.157.9.22:80', 'ecustmde.com', "$username", "$password");

sub to_post {
	my ($post_port,$to_post,$url) = @_ ;
	print "准备发送xml信息...\n";
	print "$to_post\n";
	my $user_agent_resp = $ua->request(	POST "$post_port",
										Referer => "$url",
										User_Agent => 'Jacky',
										Content_Type => 'text/xml; charset=gb2312',
										Content => $to_post);
	print "服务器回应...\n";
	print $user_agent_resp->error_as_HTML unless $user_agent_resp->is_success;
	#print $user_agent_resp->as_string;
	if ($user_agent_resp->as_string =~ /<Result>.*<\/Result>/ ) {
		print $user_agent_resp->as_string;
	} else {
		print "服务器返回为网页\n";
	}
}

sub to_get {
my ($url) = @_;
my $request = GET $url;
print "开始访问 $url ...\n";
my $response = $ua->request($request);
my ($parmlist,$localurl,$xml_string,$view_status);
if ($response->is_success) {
	#print "It worked!->" . $response->code ."\n";
	print "访问成功，开始获取网页内元素...\n";
	foreach my $tmp_1 ($response->content) {
     	#print "$tmp_1\n";
		if ( $tmp_1 =~ /<input\s*type="hidden"\s*name="__VIEWSTATE"\s*value="(.*)"\s*\/>/ ) {
        	$view_status = "__VIEWSTATE=$1";
			print "获取__VIEWSTATE成功\n";
		#print $view_status;
		}
		if ( $tmp_1 =~ /onClientClick\(\'(.*)\',\'($username)\'\)/ ) {
			$localurl = $1;
			$parmlist = $2;
			print "获取提交地址 $localurl 成功\n获取参数 $parmlist 成功\n";
		}
		if ( $tmp_1 =~ /var gparmList="(.*)"/ ) {
		$localurl = 'CourseWareCount';
		$parmlist = $1;
		print "强制设定提交地址为 $localurl \n获取参数 $parmlist 成功\n";
		}
		#if ( $tmp_1 =~ /<form name="Form1" method="post" action="(.*)" id="Form1">/) {
		#	$post_url = 'http://211.157.9.22/' . $1;
		#}
	}
	$xml_string = "<?xml version=\"1.0\" encoding=\"gb2312\"?>\r\n<Parameter>\r\n\t<Par>$localurl<\/Par>";
	my @parmlist;
	@parmlist = split /,/,$parmlist;
	for (my $i=0;$i<@parmlist;$i++){
		$xml_string = $xml_string . "\r\n\t<Par>$parmlist[$i]<\/Par>";
	}
	$xml_string = $xml_string . "\r\n<\/Parameter>\r\n";
	print "组合xml元素\n$xml_string\n";
	my $post_port = 'http://211.157.9.22/Class3.aaa';
	print "设定.net提交地址为 $post_port\n开始向提交地址递交信息\n";
	sleep (1);
	to_post($post_port,$xml_string,$url);
	#print $response->as_string;
	return $view_status;
} else {
	print "连接失败，服务器返回 -> " . $response->code . "\n";
}
}

$url = 'http://211.157.9.22/Student/DEE/StudentLearningCoursesInfo.aspx?UserID=' . "$username";
to_get($url);
sleep (1);
$url = 'http://211.157.9.22/ECUSTMDE_StudentAndLearningAdminWebUI/StudentLearningCoursesInfoDetail.aspx?StudentFileID=30978&CourseResourceID=15&StudentID=32555';
sleep (1);
my $tmp_to_post = to_get($url);
$post_url = $url unless (defined $post_url);
#print "$post_url\n";
to_post($post_url,$tmp_to_post,$url);
