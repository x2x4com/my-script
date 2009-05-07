#!/usr/bin/perl

use strict;
use File::Basename;
use POSIX qw(strftime);
use List::Util qw(max sum);


my $mongrel_log_dir = './';
my $mongrel_log_name = 'production.log';
my $archive_dir = './archive';
my $mongrel_script = '/etc/init.d/mongrel_cluster restart';
my $report_dir = './report';
my $mail_script = 'sendmail.pl';
my $user = '';
my $pass = '';
my $mongrel_log = $mongrel_log_dir . '/'. $mongrel_log_name ;

my $log = (basename $0) . '.log';
open LOG, ">>$log" or die "Can not open logfile $log, $!\n";

my $time = sub {
	my $format = shift;
	my $time_format;
	##定义返回时间的类型
	## today_full     example 20090505223834
	## todday_std   example 20090505
	## yesday_full   example 20090504223834
	## yesday_std   example 20090504
	## log  example [2009-05-05 22:38:34]
	if ( $format =~ /^log$/ ) {
		$time_format = POSIX::strftime("\[%Y-%m-%d %H:%M:%S\]", localtime(time));
	} elsif ( $format =~ /^year$/ ) {
		$time_format = POSIX::strftime("%Y", localtime(time-86400));
	} elsif ( $format =~ /^month$/ ) {
		$time_format = POSIX::strftime("%m", localtime(time-86400));
	} elsif ( $format =~ /^today_full$/ ) {
		$time_format = POSIX::strftime("%Y%m%d%H%M%S", localtime(time));
	} elsif ( $format =~ /^today_std$/ ) {
		$time_format = POSIX::strftime("%Y%m%d", localtime(time));
	} elsif ( $format =~ /^yesday_std$/ ) {
		$time_format = POSIX::strftime("%Y%m%d", localtime(time-86400));
	} elsif ( $format =~ /^yesday_full$/ ) {
		$time_format = POSIX::strftime("%Y%m%d%H%M%S", localtime(time-86400));
	}
	return $time_format;
};

sub to_log {
	my @word = @_;
	foreach my $word (@word) {	
		#print $time->('log') . " $word\n";
		print LOG $time->('log') . " $word\n";
	}
}

sub log_and_die {
		my $word = shift;
		#print $time->('log') . " $word\n";
		print LOG $time->('log') . " $word\n";
		close LOG;
		exit 1;
}


##检查配置参数
log_and_die("Can not read $mongrel_log") unless ( -r $mongrel_log );
#log_and_die("Can not execute $mongrel_script") unless ( -x $mongrel_script );

##开始切换mongrel的日志
my $yesday = $time->('yesday_std');
my $year = $time->('year');
my $month = $time->('month');

if ( ! -d $archive_dir )  {
	mkdir ($archive_dir) or log_and_die("Can not mkdir $archive_dir, $!");
} elsif ( ! -w $archive_dir ) {
	log_and_die("$archive_dir is not writeable");
}

if ( ! -d $report_dir )  {
	mkdir ($report_dir) or log_and_die("Can not mkdir $report_dir, $!");
} elsif ( ! -w $report_dir ) {
	log_and_die("$report_dir is not writeable");
}

if ( ! -d "${archive_dir}/${year}" )  {
	mkdir ("${archive_dir}/${year}") or log_and_die("Can not mkdir ${archive_dir}/${year}, $!");
} elsif ( ! -w "${archive_dir}/${year}" ) {
	log_and_die("${archive_dir}/${year} is not writeable");
}

if ( ! -d "${archive_dir}/${year}/${month}" )  {
	mkdir ("${archive_dir}/${year}/${month}") or log_and_die("Can not mkdir ${archive_dir}/${year}/${month}, $!");
} elsif ( ! -w "${archive_dir}/${year}/${month}" ) {
	log_and_die("${archive_dir}/${year}/${month} is not writeable");
}

$archive_dir = "${archive_dir}/${year}/${month}" ;


my $stats = system "mv $mongrel_log ${archive_dir}/${mongrel_log_name}_${yesday}";
log_and_die("mv $mongrel_log ${archive_dir}/${mongrel_log_name}_${yesday} failed") unless ($stats == 0);
undef $stats;

##重启mongrel_cluster以便生效新的日志文件
my @stats = `$mongrel_script`;
to_log(@stats);
#unless ( -f $mongrel_log ) {
#	system "mv ${archive_dir}/${mongrel_log_name}_${yesday} $mongrel_log";
#	log_and_die("Can not find new $mongrel_log, May be Mongrel Cluster restart failure");
#}
my $target = "${archive_dir}/${mongrel_log_name}_${yesday}";

open M_LOG, "<${archive_dir}/${mongrel_log_name}_${yesday}" or log_and_die ("Can not open ${archive_dir}/${mongrel_log_name}_${yesday}, $!");

my $controller = {};
my ($tmp_cont,$tmp_0);

#print "Please wait ...\n";

while (<M_LOG>) {
	if (/^Processing\s*([^#]+)#\w+\s*\(for/) {
		$tmp_cont = $1;
		#print "$tmp_cont\n";
		if ( ! defined $controller->{$tmp_cont}) {
			$controller->{$tmp_cont} = {};
			$controller->{$tmp_cont}->{'completed'} = [];
			$controller->{$tmp_cont}->{'view'} = [];
			$controller->{$tmp_cont}->{'db'} = [];
			$controller->{$tmp_cont}->{'urls'} = [];
			$controller->{$tmp_cont}->{'count'} = 0;
		} else {
			$controller->{$tmp_cont}->{'count'} = $controller->{$tmp_cont}->{'count'} + 1 ;
		}
	}
	if (/^Completed\s*in\s*(\d+)ms\s*\((View:\s*\d+)*\s*,?\s*(DB:\s*\d+)\)\s*|\s*200\s*OK\s*\[.*\]\s*/) {
		$controller->{$tmp_cont}->{'completed'}->[$controller->{$tmp_cont}->{'count'}] = $1;
		($tmp_0 , $controller->{$tmp_cont}->{'view'}->[$controller->{$tmp_cont}->{'count'}]) = split /:\s*/, $2;
		($tmp_0 , $controller->{$tmp_cont}->{'db'}->[$controller->{$tmp_cont}->{'count'}]) = split /:\s*/ , $3;
	}
}
close M_LOG;

##生成报告

my $report_file = $time->('yesday_std');
$report_file = $report_dir . '/mongrel_log_' . $report_file . '.csv' ;
open REPORT, ">>$report_file" or log_and_die("Can not write $report_file, $!");

select REPORT;
print "ID;Controller Name;Completed Max;Completed Avg;View Max;View Avg;DB Max;DB Avg;\n";

my $list_num = 1;
my $array_num;
foreach (keys %{$controller} ) {
	print "$list_num;$_;";
	my $max_completed = max @{$controller->{$_}->{'completed'}};
	print "$max_completed;"; 
	my $sum_completed = sum @{$controller->{$_}->{'completed'}};
	$array_num = @{$controller->{$_}->{'completed'}};
	my $avg_completed;
	if ( $array_num != 0 ) {
		$avg_completed = $sum_completed / $array_num;
	} else {
		$avg_completed = 0;
	}
	print "$avg_completed;";
	undef @{$controller->{$_}->{'completed'}};
	
	my $max_view = max @{$controller->{$_}->{'view'}};
	print "$max_view;"; 
	my $sum_view = sum @{$controller->{$_}->{'view'}};
	$array_num = @{$controller->{$_}->{'view'}};
	my $avg_view;
	if ( $array_num != 0 ) {
		$avg_view = $sum_view / $array_num;
	} else {
		$avg_view = 0;
	}
	print "$avg_view;";
	undef @{$controller->{$_}->{'view'}};
	
	my $max_db = max @{$controller->{$_}->{'db'}};
	print "$max_db;"; 
	my $sum_db = sum @{$controller->{$_}->{'db'}};
	$array_num = @{$controller->{$_}->{'db'}};
	my $avg_db;
	if ( $array_num != 0 ) {
		$avg_db = $sum_db / $array_num;
	} else {
		$avg_db = 0;
	}
	print "$avg_db;";
	undef @{$controller->{$_}->{'db'}};
	$list_num++;
	print "\n";
}
select STDOUT;
close REPORT;

##send email

close LOG;
