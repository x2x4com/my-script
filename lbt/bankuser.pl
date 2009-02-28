#!/usr/bin/perl
#************************************************************************************
#
#  This script will add a ftp user for bank
#
#  Usage: bankuser.pl [add|delete|list] bankcode
#
#  Example: bankuser.pl add 0305
#  			bankuser.pl delete 0305
#  			bankuser.pl list
#
#  Bank user rules:  1, must have a group - banks (GID=900)
#                    2, username must bank[bankcode] (example bank0105 bank0301)
#                    3, users uid must set to 9xx (901 902 903 ....)
#                    4, user home dir must at /usr/local/bankfile/bank[bankcode]
#                       (example: /usr/local/bankfile/bank0301)
#                    5, user's shell must set to /sbin/nologin
#                    6, user must lock at his home dir 
#                       (FTP setting, ProFTP is DefaultRoot ~)
#
#  Author: Jacky Xu ( Jacky.xu@livebytouch.com)
#
#*************************************************************************************

use strict;
use File::Basename;

die "You are not root\n" unless ( $< == 0 );

my $passwd = '/etc/passwd';
my $group = '/etc/group';
my $shadow = '/etc/shadow';

$| = 0 ;

my $script_name = basename $0;

#open SHADOW, "$shadow" or die "Can not open shadow file $shadow, $!\n";

my ($username,$m_uid,$m_gid,$m_home,$m_shell);
format STDOUT_TOP =
Bank users info
Name         UID   GID   Home                              Shell
-------------------------------------------------------------------------
.

format STDOUT = 
@<<<<<<<<  @>>>> @>>>>   @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   @<<<<<<<<<<<<<<<
$username, $m_uid, $m_gid,$m_home,$m_shell
.


sub usage {
	print "Usage: $script_name [add|delete|list] bankcode
Example: $script_name add 0305         
           $script_name delete 0305         
           $script_name list\n";
}

sub test_user {
	open PASSWD, "$passwd" or die "Can not open passwd file $passwd, $!\n";
	my $tmp;
	my ($username) = @_;
	foreach (<PASSWD>) {
		if ( /^$username:x:/ ) {
			$tmp = 1;
			last;
		}
	}
	close PASSWD;
	if ( $tmp == 1 ) {
		return 1;
	} else {
		return 0;
	}
}

sub next_uid {
	open PASSWD, "$passwd" or die "Can not open passwd file $passwd, $!\n";
	my (@bankuids,$next);
	foreach (<PASSWD>) {
		if ( /^(bank\d+):x:(\d+):(\d+)::(.*):(.*)$/ ) {
			# $1 is username 
			# $2 is uid
			# $3 is gid
			# $4 is user's home
			# $5 is user's shell
			push @bankuids,$2;
			next;
		}
		## Temp: for user bankbac .....
		if ( /^(bankabc):x:(\d+):(\d+)::(.*):(.*)$/ ) {
			# $1 is username 
			# $2 is uid
			# $3 is gid
			# $4 is user's home
			# $5 is user's shell
			push @bankuids,$2;
			next;
		}
		## Temp over
	}
	#print "@bankuids\n";
	close PASSWD;
	$next = 0;
	foreach my $uid (@bankuids) {
		$next = $uid if ( $uid > $next );
	}
	if ( $next > 0 ) {
		return $next+1;
	} else {
		return 901;
	}
}

sub bank_group {
	open GROUP, "$group" or die "Can not open group file $group, $!\n";
	my ($tmp,$banks_uid);
	$tmp = 0;
	foreach (<GROUP>) {
		if ( /^banks:x:(\d+):/ ) {
		$tmp = 1;
		$banks_uid = $1;
		#print "$banks_uid\n";
		}
	}
	close GROUP;
	if ( $tmp == 1 && $banks_uid == '900' ) {
		#print "Group banks find, but uid is $banks_uid\n";
		return 0;
	} elsif ( $tmp == 0 ){
		my $return_status = system "/usr/sbin/groupadd","-g 900","banks";
		die "Can not add group banks\n" unless ( $return_status == 0 );
		return 0;
	} else {
		print "Group banks find, but gid is $banks_uid\n";
		return 1;
	}
}

sub add {
	my ($bank_code) = @_;
	$username = 'bank' . "$bank_code";
	#print "Add $username\n";
	die "Group: banks(GID 900) is illegal\n" unless ( bank_group() == 0 );
	die "$username had existed...\n" unless ( test_user("$username") == 0 );
	$m_uid = next_uid();
	$m_gid = '900';
	$m_home = "/usr/local/bankfile/$username";
	$m_shell = "/sbin/nologin";
	# useradd -m -u 903 -g 900 -d /usr/local/bankfile/bank0305 -s /sbin/nologin bank0305
#	print "Account Info
#name: $username
#uid: $next_uid
#gid: 900(banks)
#home: /usr/local/bankfile/$username
#shell: /sbin/nologin
#command: useradd -m -u $next_uid -g 900 -d /usr/local/bankfile/$username -s /sbin/nologin $username\n
#Are you sure add user $username? (y/n)";
	write;
	print "Command: useradd -m -u $m_uid -g $m_gid -d $m_home -s $m_shell $username\n";
	LOOP:
	print "Are you sure add user $username? (y/n)";
	my $confim = (<STDIN>);
	chomp $confim;
	if ( $confim =~ /n|N/ ) {
		print "Cancel add user $username\n";
		exit;
	} elsif ( $confim =~ /y|Y/ ) {
		my $return_status = system "useradd", "-m", "-u", "$m_uid", "-g", "$m_gid", "-d", "$m_home", "-s", "$m_shell", "$username";
		die "Can not add user $username\n" unless ( $return_status == 0 );
		`chmod -R 755 $m_home`;
	} else {
		goto LOOP;
	}
}

sub del {
	my ($bank_code) = @_;
	$username = 'bank' . "$bank_code";
	die "$username not exist ...\n" unless ( test_user("$username") == 1 );	
	print "!!!!! Delete $username !!!!!\n";
	open PASSWD, "$passwd" or die "Can not open passwd file $passwd, $!\n";
	foreach (<PASSWD>) {
		if ( /^($username):x:(\d+):(\d+)::(.*):(.*)$/ ) {
			# $1 is username 
			# $2 is uid
			# $3 is gid
			# $4 is user's home
			# $5 is user's shell
			$m_uid = $2;
			$m_gid = $3;
			$m_home = $4;
			$m_shell = $5;
			last;
		}
	}
#	print "Account Info
#name: $username
#uid: $m_uid
#gid: $m_gid
#home: $m_home
#shell: $m_shell
#command:
#	format STDOUT = 
#@<<<<<<<<  @>>>> @>>>>   @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   @<<<<<<<<<<<<<<<
#$username, $m_uid, $m_gid,$m_home,$m_shell
#.
write;

	print "Command: userdel $username\n";
	LOOP:
    print "Are you sure delete user $username? (y/n)";
	my $confim = (<STDIN>);
	chomp $confim;
	if ( $confim =~ /n|N/ ) {
		print "Cancel delete user $username\n";
		exit;
	} elsif ( $confim =~ /y|Y/ ) {
		my $return_status = system "userdel","$username";
		die "Can not delete user $username\n" unless ( $return_status == 0 );
	} else {
		goto LOOP;
	}
}

sub list {
	open PASSWD, "$passwd" or die "Can not open passwd file $passwd, $!\n";
#	format STDOUT = 
#@<<<<<<<<  @>>>> @>>>>   @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   @<<<<<<<<<<<<<<<
#$username, $m_uid, $m_gid,$m_home,$m_shell
#.
	foreach (<PASSWD>) {
		if ( /^(bank\d+):x:(\d+):(\d+)::(.*):(.*)$/ ) {
			# $1 is username 
			# $2 is uid
			# $3 is gid
			# $4 is user's home
			# $5 is user's shell
			$username = $1;
			$m_uid = $2;
			$m_gid = $3;
			$m_home = $4;
			$m_shell = $5;
			write;
			next;
		}
		## temp for bankabc
		if ( /^(bankabc):x:(\d+):(\d+)::(.*):(.*)$/ ) {
			$username = $1;
			$m_uid = $2;
			$m_gid = $3;
			$m_home = $4;
			$m_shell = $5;
			write;
			next;
		}
	}
}

sub save {
	print "Save to file\n";
}


if ( $ARGV[0] =~ /^list$/ ) {
	list();
} elsif ( $ARGV[0] =~ /^save$/ ) {
	save();
} elsif ( ($ARGV[0] =~ /^add$/) && (defined $ARGV[1]) && ($ARGV[1] =~ /^(\d\d\d\d)$/) ) {
	add($ARGV[1]);
} elsif ( ($ARGV[0] =~ /^delete$/) && (defined $ARGV[1]) && ($ARGV[1] =~ /^(\d\d\d\d)$/) ) {
	del($ARGV[1]);
} else {
	usage();
}

## 
