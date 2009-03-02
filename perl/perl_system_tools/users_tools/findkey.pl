#!/usr/bin/perl
#
#脚本用途
#按照关键字在指定目录中的每个文件中搜索
#

use File::Basename;

my $mybase = basename $0;

sub file_help {
  print "  脚本用途: \n  按照关键字在指定目录中的每个文件中搜索\n  使用方法：$mybase 查询的目录 关键字 文件类型\n  例如： $mybase /home/abc jacky *.txt\n";
}


if (defined $ARGV[0]){
chomp ($target_dir = $ARGV[0]);
if ($target_dir =~ /-help|--help|-h/i) {
&file_help;
exit;
}
} else {
print "请指定查询目录: ";
chomp ($target_dir = <STDIN>);
}

if (defined $ARGV[1]){
chomp ($keys =  $ARGV[1]);
} else {
print "请输入你要查询的关键字(支持正则表达式):\n";
chomp ($keys =<STDIN>);
}

my $file_glob = $$ARGV[2];
if (defined $ARGV[2]){
chomp ($file_glob = $ARGV[2]);
} else {
print "请输入想要匹配的文件类型\n例如 *.txt; abc* : ";
chomp ($file_glob =<STDIN>);
if ($file_glob =~ /^\s*$/){
$file_glob = ".*";
}
}

$file_glob =~ s/\./\\./g;
$file_glob =~ s/\*/\.\*/g;
#print "$file_glob\n";

if ($^O =~ /MSWin32/) {
$dir_mode = '\\';
print "OS is windows \n";
} else {
$dir_mode = '/';
print "OS is linux|Unix \n";
}

sub seekfolders{
local ($dir)=@_;
opendir $folder, $dir or die "打开$dir出错: $!\n";
my @array;
foreach (readdir $folder) {
unless (/(^\.$|^\.\.$)/) {
push @array,$_;
}
}
#print @array . "\n";
#$endi = @array;

for(my $i=0;$i<@array;$i++){
#print $i.$dir."$dir_mode".$array[$i]."\n";
if (-f $dir.$dir_mode.$array[$i] && $array[$i] =~ /$file_glob/i){
#print $dir.$dir_mode.$array[$i]."\n";
open $file_match, $dir.$dir_mode.$array[$i] or die "无法打开${dir}${dir_mode}$array[$i]: $!\n";
my $count = 1;
foreach (<$file_match>){
  if (/$keys/) {
  print ("Filename:".$dir."$dir_mode".$array[$i]." in Line:$count\n$_\n");
  }
  $count += 1;
}
close($file_match);
closedir($folder);
next;
}
}

for(my $i=0;$i<@array;$i++) {
if (-d $dir.$dir_mode.$array[$i]){
&seekfolders($dir.$dir_mode.$array[$i]);
}
}
closedir($folder);
return;
}

&seekfolders($target_dir);

