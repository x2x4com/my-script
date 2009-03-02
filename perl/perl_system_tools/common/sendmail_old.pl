#!/usr/bin/perl
#**********************************************************
#
# Script Name:   sendmail.pl
# Script Author: jacky.xu@serversupport.cn
# Created Date:  2008-8-25
# Function desc: 1. send email
#
# Script Usage:  sendmail.pl server:mailserver user:username pass:password to:sendto[,sendto..] cc:sendtocc[,sendtocc..] from:mailfrom sub:subject attach:attachment message:mailbody
#		server:***  	#smtp server
#		user:***	#auth username
#		pass:***	#auth user's password
#		to:***		#sender to list, use "," to divide
#		cc:***		#sender cc list, use "," to devide
#		from:***	#set up mail come from
#		sub:"***"	#mail subject
#		attach:"***"	#attachment to mail
#		message:	#mail body
# 
#**********************************************************

use strict;
use File::Basename;
## Please install Authen::SASL Net::SMTP_auth MIME::Lite
## use root run  1, perl -MCPAN -e "install Authen::SASL"
##		 2, perl -MCPAN -e "install Net::SMTP_auth"
##		 3, perl -MCPAN -e "install MIME::Lite"
use Net::SMTP_auth;
use MIME::Lite;

my $scriptbasename = basename $0;
my ($par_count,@par_final,$mailserver,$user,$pass,$mailto,@mailto,$mailtocc,@mailtocc,$mailfrom,$subject,$attachment,@attachment,$text,$attach_test,$mylogopen);
#my $mylogfile = 'log/sendmail.log';

#my $mylogdir = dirname $mylogfile;
#my $myscriptdir = basename $0;
#if (! -d $mylogdir){
#print "[Warn] $mylogdir not find, auto create it\n";
#mkdir "log", 0755 or die "Can't mkdir log @ $myscriptdir: $!\n";
#}

## logfile handle ##
#open $mylogopen, ">>$mylogfile" or die "Can't write $mylogfile, $!\n";

sub script_help {
    print "
Useage: $scriptbasename filed:value
\tFiled list:
\tserver:***\t\t#smtp server
\tuser:***\t\t#auth username
\tpass:***\t\t#auth user's password
\tto:***\t\t\t#sender to list, use \",\" to divide
\tcc:***\t\t\t#sender cc list, use \",\" to devide
\tfrom:***\t\t#set up mail come from
\tsub:\"***\"\t\t#mail subject
\tattach:\"***\"\t\t#attachment to mail [optional parameters]
\tmessage:\t\t#mail body\n
Example: 
$scriptbasename server:mail.livebytouch.com user:test\@livebytouch.com pass:111111 to:user1\@sina.com,user2\@sina.com cc:admin\@163.com,admin2\@163.com from:test sub:\"Test mail from perl sendmail\" attach:/home/test/123.txt message:\"mailbody\"\n";
exit 3;
}

#if (! defined @ARGV){
#	warn "Error: no parameter find!\n";
#	&script_help;
#}

## 帮助文件 ##
foreach (@ARGV) {
	&script_help if (/\b-?(h|help)\b/i);
}
## 将命令行传入的参数，按照一定格式去空格 ##
for (my $i=0;$i<@ARGV;$i++) {
	#print "$ARGV[$i]\n";
	if ($ARGV[$i] =~ /^\w+:(.*)*$/) {
	push @par_final,$ARGV[$i];
	$par_count++;
	next;
	}
	@par_final[$par_count-1] .= " $ARGV[$i]";
}
#foreach (@par_final) { ##
#	print "$_\n"; ##
#} ##
#exit; ## for test

#@par_final = @ARGV;
## 按照 field 传递变量 ##
foreach (@par_final) {
	if (/^server:(.*)/){
		$mailserver = $1;
		#print "\$mailserver=$mailserver\n";
		next;
	} elsif (/^user:(.*)/){
        	$user = $1;
        	#print "\$user=$user\n";
        	next;
        } elsif (/^pass:(.*)/){
		$pass = $1;
		#print "\$pass=$pass\n";
		next;
	} elsif (/^to:(.*)/){
		$mailto = $1;
		## 过滤邮件格式 ##
		if ($mailto =~ /^\w+([\.|-|_]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+(,\w+([\.|-|_]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+)*$/){
		@mailto = split (/,/, $mailto);
		#print "\@mailto=@mailto\n";
		next;
		} else {
		print "user format error\n";
		exit 3;
		}
	} elsif (/^cc:(.*)/){
		$mailtocc = $1;
		if ($mailto =~ /^\w+([\.|-|_]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+(,\w+([\.|-|_]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+)*$/){
		@mailtocc = split (/,/, $mailtocc);
		#print "\@mailtocc=@mailtocc\n";
		next;
		} else {
		print "cc user format error\n";
		exit 3;
		}
	} elsif (/^from:(.*)/){
		$mailfrom = $1;
		#print "\$mailfrom=$mailfrom\n";
		next;
	} elsif (/^sub:(.*)/){
		$subject = $1;
		#print "\$subject=$subject\n";
		next;
	} elsif (/^attach:(.*)/){
		$attachment = $1;
		@attachment = split (/,/, $attachment);
		#print "\@attachment=@attachment\n";
		next;
	} elsif (/^message:(.*)/){
		$text = $1;
		#print "\$text=$text\n";
		next;
	}
}

## 处理空值 ##
if (! defined $mailserver) {
print "[Error] Can not find mailserver.\n";
&script_help;
}

if (! defined $user) {
print "[Error] Can not find user.\n";
&script_help;
}

if (! defined $pass) {
print "[Error] Can not find user's password.\n";
&script_help;
}

if (! defined $mailfrom) {
print "[Warn] Can not find mail from, use sender address\n";
$mailfrom = $user;
}

if (! defined @mailto) {
print "[Error] Can not find recipients.\n";
&script_help;
}

if (! defined $subject){
print "[Warn] Can not find subject, set default.\n";
$subject = "This mail send via perl sendmail ($scriptbasename) scrpit";
}

if (! defined $text){
print "[Warn] Can not find message body, set default.\n";
$text = 'mail body is null.';
}

## 根据传入参数判断是否带有参数，并且判断文件是否可读
if (defined @attachment){
foreach (@attachment){
	die "\n[Error] Open $_ error, $!\n" if (! -r $_);
} 
$attach_test = 1;
}

## 标准发送函数，不带附件 ##
sub standmail {
#select $mylogopen;
my $smtp = Net::SMTP_auth->new($mailserver,
			  Timeout => "120",
			  Debug => 0)
	or die "error to connect $mailserver, $!\n";

###SMTP AUTH with MD5###
$smtp->auth('CRAM-MD5',$user,$pass) or die "Auth Error,$!\n";
## 轮流发送 to ##
foreach my $mailtosend (@mailto) {
$smtp->mail($mailfrom);
$smtp->to($mailtosend);
$smtp->data();
$smtp->datasend("To: $mailto\n");
$smtp->datasend("Cc: $mailtocc\n");
$smtp->datasend("From:$mailfrom\n");
$smtp->datasend("Subject: $subject\n");
$smtp->datasend("\n");
$smtp->datasend("$text\n\n");
$smtp->dataend();
}
## 轮流发送 cc ##
if (defined @mailtocc){
foreach my $mailtoccsend (@mailtocc) {
$smtp->mail($mailfrom);
$smtp->cc($mailtoccsend);
$smtp->data();
$smtp->datasend("To: $mailto\n");
$smtp->datasend("Cc: $mailtocc\n");
$smtp->datasend("From:$mailfrom\n");
$smtp->datasend("Subject: $subject\n");
$smtp->datasend("\n");
$smtp->datasend("$text\n\n");
$smtp->dataend();
}
}
$smtp->quit;
#close $mylogopen;
return 0;
}
## 带附件发送 ##
sub mimemail {
#select $mylogopen;
my $smtp = Net::SMTP_auth->new($mailserver,
                          Timeout=>120,
                          Debug=>0)
        or die "error to connect $mailserver, $!\n";

###SMTP AUTH with MD5###
$smtp->auth('CRAM-MD5',$user,$pass) or die "Auth Error,$!\n";

## Send via MIME ##
my $mimebody = MIME::Lite->new( From => $mailfrom,
                                To   => $mailto,
				Cc   => $mailtocc,
                                Subject => $subject,
                                Type => 'multipart/mixed')
        or die "Error Creating MIME body: $!\n";

## Add parts ##

$mimebody->attach(Type => 'TXT',
                 Data => $text);

## Add attachment ##
foreach my $attachment (@attachment){
$mimebody->attach(Type => 'AUTO',
                Path => $attachment)
        or warn "Error attaching file $attachment, $!\n";
}

my $str = $mimebody->as_string() or warn "Convert the message as a string: $!\n";

foreach my $mailtosend (@mailto){
## MIME SMTP ##
$smtp->mail($mailfrom);
$smtp->to($mailtosend);
$smtp->data();
$smtp->datasend("$str");
}
if (defined @mailtocc){
foreach my $mailtoccsend (@mailtocc){
## MIME SMTP ##
$smtp->mail($mailfrom);
$smtp->cc($mailtoccsend);
$smtp->data();
$smtp->datasend("$str");
}
}
$smtp->quit;
#close $mylogopen;
return 0;
}

### chose sub ###
if ($attach_test) {
#   print "\nfind attachment, use mimemail\n";
   &mimemail;
} else {
#   print "\nno attachment, use standmail\n";
   &standmail;
}
exit 0;
