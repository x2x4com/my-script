#!/usr/bin/perl

use strict;

die "Parameter Error\nUsage: script reg.log save_file\n" unless (@ARGV == 2);

open REG_LOG, "<$ARGV[0]" or die "Can not find $ARGV[0], $!\n";
open SAVE_FILE, ">$ARGV[1]" or die "Can not write to @ARGV[1], $!\n";

my @match_ip;
my $same_ip = 0;
my $webname_null = 0;

foreach (<REG_LOG>) {
	if (/webname:null/) {
		$webname_null = 1;
		next;
	} elsif (/userinfo:(\d+\.\d+\.\d+\.\d+)/) {
		if ($webname_null) {
			$same_ip = 0;
			foreach my $tmp_ip (@match_ip) {
				if ($1 == $tmp_ip) {
				$same_ip = 1;
				#print "SAME IP = $1\n";
				last;
				}
				next;
			}
			if ($same_ip) {
				$webname_null = 0;
				next;
			}
			push @match_ip, $1;
			print "Find null webname, IP: $1\n";
			print SAVE_FILE "##########NEW RECORD##########\n$_";
			print "Get $1 info\n";
			print SAVE_FILE "Get $1 info\n";
			my @ip_info = `whois $1`;
			foreach my $ip_info_tmp (@ip_info) {
				if ($ip_info_tmp =~ /^\w+:.*$/){
				print SAVE_FILE "$ip_info_tmp";
				next;
				} elsif ($ip_info_tmp =~ /^\s*$/) {
				print SAVE_FILE "$ip_info_tmp";
                next;
				}
				next;
			}
			$webname_null = 0;
			next;
		} else {
			$webname_null = 0;
			next;
		}
	} else {
		next;
	}
}

close REG_LOG;
