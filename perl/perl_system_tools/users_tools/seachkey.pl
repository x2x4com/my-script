#!/usr/bin/perl

use File::Basename;

my $mybase = basename $0;
if ( @ARGV <= 0 ) {
	die "错误，无参数\n使用方法：$mybase 文件名 关键字 (如需输入正则表达式，关键字请留空)\n";
}

open SOURCE,"<$ARGV[0]"
	or die	"无法锁定$ARGV[0], $!";

if (defined $ARGV[1]){
chomp ($keys = $ARGV[1]);
} else {
print "请输入你要查询的关键字(支持正则表达式)\n";
chomp ($keys =<STDIN>);
}
my $count = 1;
foreach (<SOURCE>) {
	chomp $_;
	if (/$keys/) {
		print "$count\t$_\n";
	} else {
		print "$count\t此行没有匹配$keys , 原内容为:\t$_\n";
	}
	$count += 1;
} 
