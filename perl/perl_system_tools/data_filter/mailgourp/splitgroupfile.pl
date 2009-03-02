#!/usr/bin/perl
#*********************************************
#  This script will auto split group list file
#  for qmail system
#  Group list file format like this:
#	[groupname]
#	userbox@example.com
#	userbox2@example.com
#
#*********************************************

use strict;
use File::Basename;

$| = 0;

my ($source_file,$save_dir,$save_file,$source,$group_file);
# $^O =~ /MSWin32/ is windows;

if (defined $ARGV[0]) {
	$source_file = $ARGV[0];
	print "Source file is $source_file\n";
} else {
	print "Please input group list file full patch: ";
	$source_file = (<STDIN>);
	if ($^O =~ /MSWin32/) {
		chomp $source_file;   ## delete \n
		chop $source_file;    ## delete \r
		print "Source file is $source_file\n";
	} else {
		chomp $source_file;	
		print "Source file is $source_file\n";
	}
}

$save_dir = dirname $source_file;
print "Save dir is $save_dir\n";

open $source, "<$source_file" or die "Can not open $source_file, $!\n";
chdir $save_dir or die "Can not goto $save_dir, $!\n";

foreach (<$source>) {
	next if (/^#/);
	next if (/^\s*$/);
	if (/^\[FINISH\]/) {
		print "FINISH\n";
		close SAVE;
		next;
	}
	if (/^\[(.*)\]/) {
		close SAVE;
		$group_file = '.qmail-' . lc($1);
		if ( -w $group_file ) {
			unlink("$group_file");
		}
		open SAVE, ">>$group_file" or die "Can not save $group_file, $!\n";
		print "Group name is $1\n";
		next;
	}
	print "File: $group_file added: $_";
	print SAVE "$_";
}

close $source;


