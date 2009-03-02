#!/usr/bin/perl

use File::Basename;
$scriptbase = basename $0;
$curl = '/usr/bin/curl';

if (@ARGV < 2) {
	die "参数错误!\n使用方法：$scriptbase 访问次数 访问的目标\n";
}

-x $curl or die "无法执行$curl： $!\n";

$runtimes = shift;

if ( $runtimes =~ /\d+/ ){
for ($i=1;$i<$runtimes+1;$i++) {
print "第$i次访问\n";
print "$ARGV[0]\n";
	if (system $curl, "-o","/tmp/tmpvist", "$ARGV[0]") {
		die "打开$ARGV[0]失败,runtime = $i\n";
	}
unlink "/tmp/tmpvist" or warn "无法删除临时文件\n";
}
} else { 
	die "访问次数输入错误！\n";
}
