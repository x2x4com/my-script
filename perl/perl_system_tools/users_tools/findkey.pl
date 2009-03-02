#!/usr/bin/perl
#
#�ű���;
#���չؼ�����ָ��Ŀ¼�е�ÿ���ļ�������
#

use File::Basename;

my $mybase = basename $0;

sub file_help {
  print "  �ű���;: \n  ���չؼ�����ָ��Ŀ¼�е�ÿ���ļ�������\n  ʹ�÷�����$mybase ��ѯ��Ŀ¼ �ؼ��� �ļ�����\n  ���磺 $mybase /home/abc jacky *.txt\n";
}


if (defined $ARGV[0]){
chomp ($target_dir = $ARGV[0]);
if ($target_dir =~ /-help|--help|-h/i) {
&file_help;
exit;
}
} else {
print "��ָ����ѯĿ¼: ";
chomp ($target_dir = <STDIN>);
}

if (defined $ARGV[1]){
chomp ($keys =  $ARGV[1]);
} else {
print "��������Ҫ��ѯ�Ĺؼ���(֧��������ʽ):\n";
chomp ($keys =<STDIN>);
}

my $file_glob = $$ARGV[2];
if (defined $ARGV[2]){
chomp ($file_glob = $ARGV[2]);
} else {
print "��������Ҫƥ����ļ�����\n���� *.txt; abc* : ";
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
opendir $folder, $dir or die "��$dir����: $!\n";
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
open $file_match, $dir.$dir_mode.$array[$i] or die "�޷���${dir}${dir_mode}$array[$i]: $!\n";
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

