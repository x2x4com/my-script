#!/usr/bin/perl

use strict;

my $lenth = 8;
my @source = ('1'..'9','$','a'..'z','A'..'Z','!','@','#','%','&');
my $password;
for (my $i=0;$i<$lenth;$i++) {
	## rand 取 0~@source 随机数 init 取整
	$password .= $source[int (rand @source)];
}

print "$password \n";
