#!/usr/bin/perl
#****************************************
#  This is script will create and verify
#  config files
#
#
#
#
#
#
#****************************************

use strict;

sub conf_file {
open SAVE, ">setup.conf" or die "Can not write setup.conf, $!\n";

my $qmail = {	default => '/var/qmail',
				common => "Please input qmail install dir(default is /var/qmail): "};

my $vpopmail = {	default => '/home/vpopmail',
					common => "Please input vpopmail install dir(default is /home/vpopmail): "};

my $mysql = {	root_user => 'root',
				root_pass => 'root',
				vpop_user => 'vpopmail',
				vpop_pass => 'vpopmail',
				vpop_table => 'vpopmail' };

START:

print $qmail->{"common"} ;
$qmail->{input} = <STDIN>;
chomp $qmail->{input};
if ($qmail->{input} =~ /\w+/) {
	$qmail->{default} = $qmail->{input};
}

print $vpopmail->{"common"} ;
$vpopmail->{input} = <STDIN>;
chomp $vpopmail->{input};
if ( $vpopmail->{input} =~ /\w+/) {
    $vpopmail->{default} = $vpopmail->{input};
}

print "Please input mysql root username(default is root): ";
$mysql->{root_user_input} = <STDIN>;
chomp $mysql->{root_user_input};
if ( $mysql->{root_user_input} =~ /\w+/) {
    $mysql->{root_user} = $mysql->{root_user_input};
}

print "Please input mysql root passwd(default is root): ";
$mysql->{root_pass_input} = <STDIN>;
chomp $mysql->{root_pass_input};
if ( $mysql->{root_pass_input} =~ /\w+/) {
    $mysql->{root_pass} = $mysql->{root_pass_input};
}

print "Please input table name to create for vpopmail(default is vpopmail): ";
$mysql->{vpop_table_input} = <STDIN>;
chomp $mysql->{vpop_table_input};
if ( $mysql->{vpop_table_input} =~ /\w+/) {
    $mysql->{vpop_table} = $mysql->{vpop_table_input};
}

print "Please input username for vpopmail(default is vpopmail): ";
$mysql->{vpop_user_input} = <STDIN>;
chomp $mysql->{vpop_user_input};
if ( $mysql->{vpop_user_input} =~ /\w+/) {
    $mysql->{vpop_user} = $mysql->{vpop_user_input};
}

print "Please input passwd for " . $mysql->{vpop_user} . "(default is vpopmail): ";
$mysql->{vpop_pass_input} = <STDIN>;
chomp $mysql->{vpop_pass_input};
if ( $mysql->{vpop_pass_input} =~ /\w+/) {
    $mysql->{vpop_pass} = $mysql->{vpop_pass_input};
}

my ($domain,$postmaster);
undef $domain;
undef $postmaster;
until ( $domain =~ /\w+/ ) {
	print "Please input your first domain\n(If your mail address is user\@domain.com, your domain name is \"domain.com\"): \n";
	$domain = <STDIN>;
}
chomp $domain;

until ( $postmaster =~ /\w+/ ) {
	print "Please input your postmaster password for $domain: ";
	$postmaster = <STDIN>;
}

chomp $postmaster;

print "========================================\n";
print "| qmail_dir='".$qmail->{default}."'\n";
print "| vpopmail_dir='".$vpopmail->{default}."'\n";
print "| mysql_root='".$mysql->{root_user}."'\n";
print "| mysql_pass='".$mysql->{root_pass}."'\n";
print "| vpopmail_table='".$mysql->{vpop_table}."'\n";
print "| vpopmail_user='".$mysql->{vpop_user}."'\n";
print "| vpopmail_pass='".$mysql->{vpop_pass}."'\n";
print "| domain=\'$domain\'\n";
print "| post_pass=\'$postmaster\'\n";
print "========================================\n";
print "Is this ok? (y/n): ";

my $confim;
undef $confim;
until ( $confim =~ /[y|Y|n|N]/) {
	$confim = (<STDIN>);
	chomp $confim;
}

goto START if ( $confim =~ /[n|N]/ );

print SAVE "qmail_dir='".$qmail->{default}."'\n";
print SAVE "vpopmail_dir='".$vpopmail->{default}."'\n";
print SAVE "mysql_root='".$mysql->{root_user}."'\n";
print SAVE "mysql_pass='".$mysql->{root_pass}."'\n";
print SAVE "vpopmail_table='".$mysql->{vpop_table}."'\n";
print SAVE "vpopmail_user='".$mysql->{vpop_user}."'\n";
print SAVE "vpopmail_pass='".$mysql->{vpop_pass}."'\n";
print SAVE "domain=\'$domain\'\n";
print SAVE "post_pass=\'$postmaster\'\n";

close SAVE;

exit 0;

}

sub check_files {
	use File::Basename;
	my $pwd = dirname $0;
	my @source_list = ('autorespond-2.0.5.tar.gz','clamav-0.94.tar.gz','courier-authlib-0.58.tar','courier-imap-4.1.1.tar.bz2','daemontools-0.76-man.tar.gz','daemontools-0.76.tar.gz','ezmlm-0.53.tar.gz','ezmlm-idx-0.42.tar.gz','igenus_2.0.2_20040901_release.tgz','igenus_admin_0.1.tgz','isoqlog-2.2.1.tar.gz','maildrop-2.0.2.tar.bz2','netqmail-1.05.tar.gz','qlogtools-3.1.tar.gz','qmailadmin-1.2.11.tar.gz','qmailanalog-0.70.tar.gz','qmailmrtg7-4.2.tar.gz','qmail-scanner-2.05.tgz','qmail-toaster-0.9.1.patch.bz2','qms-analog-0.4.4.tar.gz','squirrelmail-1.4.17.tar.gz','tnef-1.4.3.tar.gz','toaster-scripts-0.9.1.tar.gz','ucspi-tcp-0.88.tar.gz','vpopmail-5.4.25.tar.gz');
	my @patch_list = ('chkuser-0.6.mysql.patch','chkuser-0.6.patch','daemontools-0.76.errno.patch','qlogtools_errno.patch','qmailanalog-0.70.errno.patch','ucspi-tcp-0.88.a_record.patch','ucspi-tcp-0.88.errno.patch','ucspi-tcp-0.88.nobase.patch'
);
	my @doc_list = ('ezmlm.sql','iGENUS.sql','over-quota.msg','quotawarn.msg');
	foreach (@source_list) {
		die "miss source/$_\n" unless ( -f "$pwd/source/$_" );
	}
	foreach (@patch_list) {
		die "miss patchs/$_\n" unless ( -f "$pwd/patchs/$_");
	}
	foreach (@doc_list) {
		die "miss docs/$_\n" unless ( -f "$pwd/docs/$_");
	}
	exit 0;
}

sub init_stats {
	## total step = 18 ##
	my $max_c = 19;
	my $stats = 'install.stats';
	open STATS, ">$stats" or die "can not open $stats, $!\n";
	for (my $count = 1;$count< $max_c;$count++) {
		print STATS "step${count}=0\n";
	}
	close STATS;
}


if ( $ARGV[0] =~ /^init_conf$/ ) {
	conf_file();
} elsif ( $ARGV[0] =~ /^check_files$/ ) {
	check_files();
} elsif ( $ARGV[0] =~ /^init_stats$/ ) {
	init_stats();
} else  {
	die "failed, please run install.sh\n"
}
