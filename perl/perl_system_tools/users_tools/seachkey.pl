#!/usr/bin/perl

use File::Basename;

my $mybase = basename $0;
if ( @ARGV <= 0 ) {
	die "�����޲���\nʹ�÷�����$mybase �ļ��� �ؼ��� (��������������ʽ���ؼ���������)\n";
}

open SOURCE,"<$ARGV[0]"
	or die	"�޷�����$ARGV[0], $!";

if (defined $ARGV[1]){
chomp ($keys = $ARGV[1]);
} else {
print "��������Ҫ��ѯ�Ĺؼ���(֧��������ʽ)\n";
chomp ($keys =<STDIN>);
}
my $count = 1;
foreach (<SOURCE>) {
	chomp $_;
	if (/$keys/) {
		print "$count\t$_\n";
	} else {
		print "$count\t����û��ƥ��$keys , ԭ����Ϊ:\t$_\n";
	}
	$count += 1;
} 
