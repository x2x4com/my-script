#!/usr/bin/perl
#******************************************************
# 此脚本将在指定的时间内自动监控JAVA进程，如果进程不存在，自动重启
# 并且发送邮件通知
# 脚本编码: UTF-8
#
#
#
#
#******************************************************

use strict;
use File::Basename;
use POSIX qw(strftime);
use Sys::Hostname;

## 变量设定 ##
my $jboss_log_dir = '/usr/local/jboss/jboss/server/default/log';
my $jboss_log_name = 'server.log';
my $jboss_batch = '/root/bin/jboss.sh';
my %ap_port_list = (   '65520' => 'Bankcomm',
                    '65528' => 'Port 28',
                    '65529' => 'Port 29',
                    '65530' => 'Port 30',
                    '65532' => 'Port 32',
                    '65533' => 'Port 33',
                    '65534' => 'Port 34',
                    '65535' => 'Port 35'
                );

my $stats_log = '/root/jboss_status.log';
my $sleep_time = '30';
## 设定是否发送邮件 1为发送，0不发送
my $sendmail = '1';
my $mail_proc = '/home/jacky/scripts/perl/perl_system_tools/common/sendmail';
my $mail_server = 'mail.livebytouch.com';
my $mail_user = 'jacky.xu@livebytouch.com';
my $mail_user_pass = '';
my $mail_to = 'jacky.xu@livebytouch.com';
my $mail_from = 'Jacky Xu';
my $host = hostname;

## defind time format ##
my $time = sub {
                my ($para) = @_;
                my $time;
                # 2 format 1, tolog 2, today , default is today
                if ( $para =~ /^tolog$/ ) {
                    $time = POSIX::strftime("\[%Y-%m-%d %H:%M:%S\]", localtime(time));
                } else {
                    $time = POSIX::strftime("%Y-%m-%d", localtime(time));
                }
                return $time;
};
## defind time format over ##

#my $lock = dirname $stats_log . '/' . basename $0;
#print "$lock\n" . $time->('tolog') . "\n";

my $failed_info;
my $html_body;


## 测试变量值是否合法 ##
#die "Can not open $jboss_log_dir/$jboss_log_name\n" unless (-f "$jboss_log_dir/$jboss_log_name");
#die "Can not execute $jboss_batch\n" unless (-x "$jboss_batch");
#if ($sendmail) { die "Can not execute $mail_proc\n" unless (-x "$mail_proc"); }

sub mail {
    #print "@_\n";
    my ($body) = @_;
    my $tmp_msg = "This script just for test, when jboss process lost, it do nothing<br>";
	$body = $tmp_msg . $body;
    #print "$body\n";
    `$mail_proc server:$mail_server user:$mail_user pass:$mail_user_pass to:$mail_to from:$mail_from sub:"$host Warning Mail" type:html message:"$body" 2>&1 >>$stats_log `;
	#print "Mail status = $aa\n";
    #system "$mail_proc", "server:$mail_server", "user:$mail_user", "pass:$mail_user_pass", "to:$mail_to", "from:$mail_from", "sub:$host Warning Mail","type:html", "message:$body";
}

sub test_port {
    my @sys_java_port = `netstat -antp | grep java | awk '{print $4}'| cut -d ":" -f 4`;
    my %tmp = %ap_port_list;

    foreach (@sys_java_port) {
        chomp;
        $_ =~ s/^\s*(\d+)\s*$/$1/g;
        if (/^655\d\d/) {
                foreach my $tmp1 (keys %tmp) {
                        delete $tmp{"$tmp1"} if ( $tmp1 =~ /^$_/ );
                }
        }
    }
    
    #clean up $failed_info;
    $failed_info = '';
    my $failed_port_count;
    foreach (keys %tmp) {
        if (/^655\d\d/){
                $failed_info .= $tmp{$_} . " Port: " . "$_ lost" . "<br>";
                $failed_port_count++;
        }
    }
    
    #print "$failed_port_count";
    
    $html_body = "<TABLE CELLSPACING='0' CELLPADDING='0' WIDTH='80%' BORDER='1'><TR><TD colspan='2' align='center'>System Warning Mail</TD></TR><TR><TD width='30%' align='left'>Host: </TD><TD>$host</TD></TR><TR><TD>Monitor Details: </TD><TD>Monitor jboss process</TD></TR><TR><TD align='left' valign='middle'>Failed Details: </TD><TD>$failed_info</TD></TR><TR><TD>Failed Actions: </TD><TD>$jboss_batch stop <br> $jboss_batch start</TD></TR></TABLE>";

    if ( $failed_port_count > 0 ) {
        return 0;
    } else {
        return 1;
    }
    
}

sub failed_action {
    #`$jboss_batch stop 2>&1 >>$stats_log`;
    sleep 10;
    #`$jboss_batch start 2>&1 >>$stats_log`;
    sleep 50;
    if ( &test_port == 1 ){
        $html_body = 'Restart ... OK';
    } else {
        $html_body = 'Restart ... Fail';
    }
}

while (1) {;
if (&test_port == 0) {
    mail($html_body) if ($sendmail);
    &failed_action;
    mail($html_body) if ($sendmail);
}
sleep $sleep_time;
}
