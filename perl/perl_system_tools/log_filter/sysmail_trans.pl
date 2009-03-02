#!/usr/bin/perl

#**********************************************************
#
# Script Name:   sysmail_trans.pl
# Script Author: jacky.xu@serversupport.cn
# Created Date:  2008-09-26
# Function desc: transmit user's system mail (mail => /var/spool/user)
#
# Script Usage:  
#
# Running OS: Linux/Unix only
# 
#**********************************************************


#use strict;
#use File::Path;
use File::Copy;
use POSIX qw/strftime/;
use Sys::Hostname;


## Read ARGV ##
#if (! defined $ARGV[0]){
#	die "[Error] Miss user, Useage: sysmail_trans.pl username\n";
#}


## User configure ##
my $user = 'root';
my $mail_spool = '/var/spool/mail';
my $mail = { server => 'mail.livebytouch.com',
      user => 'jacky.xu@livebytouch.com',
      pass => '123456',
      to => 'zhetao.su@livebytouch.com,arthur.wang@livebytouch.com,hugo.lu@livebytouch.com',
      cc => 'jacky.xu@livebytouch.com',
      from => 'Jacky Xu' };
my $perl_sendmail = '/root/sendmail.pl';
my $tmp = "/tmp/${user}_mail_trans";
my $mail_source_arch = '/root/arch';

## init ##
my ($mail_spool_file);
my $yymmdd = strftime("%y-%m-%d", localtime);
my $host = hostname;

#print "$host \n";exit 0;

## Test Configure ##
die "[Error] Can not find $mail_spool/$user\n" if (! -f "$mail_spool/$user");
my ($file_dev, $file_ino, $file_mode, $file_nlink, $file_uid, $file_gid, $file_rdev, $file_size, $file_atime, $file_mtime, $file_ctime, $file_blksize, $file_blocks)
			= stat "$mail_spool/$user";
#print "$file_dev, $file_ino, $file_mode, $file_nlink, $file_uid, $file_gid, $file_rdev, $file_size, $file_atime, $file_mtime, $file_ctime, $file_blksize, $file_blocks\n";

## $< is script runnig user's UID ##
if ( $file_uid != $< ) {
	die "[Error] test $mail_spool/$user owner failure. You UID=$<, file owner UID=$file_uid\n";
} elsif ( $file_size == 0 ) {
	print "$mail_spool/$user no record\n";
	exit 0;
}

if (! -d "$tmp"){
	mkdir "$tmp" or die "[Error] Can not create $tmp, $!\n";
}
if (! -d "$mail_source_arch"){
	mkdir "$mail_source_arch" or die "[Error] Can not create $mail_source_arch/arch, $!\n";
}

if ( ! -w "$mail_spool/$user" ) {
	chmod 0640,"$mail_spool/$user" or die "[Error] Can not set mask $mail_spool/$user to 640, $!\n";
}

move ("$mail_spool/$user","$mail_source_arch/${user}_${yymmdd}") or die "[Error] Can not move $mail_spool/$user\n";

copy ("$mail_source_arch/${user}_${yymmdd}","$tmp/$user") or die "[Error] Can not copy source to $tmp\n";

$tar_status = system "/bin/tar","-zcPf","$mail_source_arch/${user}_${yymmdd}.tar.gz","$mail_source_arch/${user}_${yymmdd}";
if ( $tar_ststus != 0 ){
	warn "[Warn] Compress $mail_source_arch/arch/${user}_${yymmdd} failure\n";
}

unlink "$mail_source_arch/${user}_${yymmdd}";

## open mail spool file ##
open $mail_spool_file, "<$tmp/$user" or die "[Error] Can not open $tmp/$user, $!\n";
my $filecount = 0;
foreach (<$mail_spool_file>) {
	if (/^From *.*\@.* *\w+ *\w+ \d+ *\d+:\d+:\d+ *\d+$/) {
		close ($data_save[$filecount]);
		$filecount++;
		$data_to_save = "${user}_mail_${yymmdd}_$filecount";
		open $data_save[$filecount], ">$tmp/$data_to_save.txt";
		select $data_save[$filecount];
		print $_;
		next;
	} 
	print $_;
	next;
}
close ($data_save[$filecount]);
close ($mail_spool_file);
select STDOUT;

for (my $i=1;$i<$filecount+1;$i++) {
	$data_to_save = "${user}_mail_${yymmdd}_$i";
	$mailstatus = system "$perl_sendmail","server:$mail->{server}","user:$mail->{user}","pass:$mail->{pass}","to:$mail->{to}","cc:$mail->{cc}","sub:[$yymmdd] $host #$i ${user}'s system mail","message:This is $i, Total is $filecount.        Mail from:$host ", "attach:$tmp/$data_to_save.txt","from:Jacky";
	if ( $mailstatus == 0 ){
		unlink "$tmp/$data_to_save.txt";
	}
}
unlink "$tmp/$user" or warn "[Warn] Can not delete $tmp/$user\n";
unless (rmdir "$tmp") {
	system "$perl_sendmail","server:$mail->{server}","user:$mail->{user}","pass:$mail->{pass}","to:$mail->{to}","cc:$mail->{cc}","sub:[$yymmdd] $host Warn Mail From System Mail Trans","message:Some mail send failed, please check $tmp.        Mail from:$host","from:Jacky";
}
