#!/usr/bin/perl


my $recordline = 0;
my %iprecord;
my @finalrecord;

## 检查参数传入 ##
if (defined $ARGV[0]) {
  chomp (our $filename = $ARGV[0]);
} else { 
  print "请输入查询文件名：";
  chomp (our $filename = <STDIN>);
}

## 检查参数传入 ##
if (defined $ARGV[1]) {
  chomp (our $filetosave = $ARGV[1]);
} else {
  print "请输入要保存查询内容的文件：";
  chomp (our $filetosave = <STDIN>);
}

## 打开目标文件 ##
open $somefile,$filename or die "无法打开目标文件$filename : $!\n";
## 打开保存查询内容的文件 ##
open $filesave, ">$filetosave" or die "无法打开保存文件$filetosave: $!\n";

foreach (<$somefile>) {
## 捕捉直接换行,如果符合条件，$recordline自加1，然后直接查询下一行 ##
  if (/^.$/s){
    $recordline++;
    next;
  }
## 捕捉inetnum字段 ##
  if (/^inetnum:/){
  ## 拼接 $inetnum 使其成为唯一的变量名字 ##
  our $inetnum = "$recordline" . "inet";
  ## 删除 $_ 的回车符 ##
  chomp;
  ## 赋值散列$iprecord{$inetnum}值为当前行##
  $iprecord{$inetnum} = "$_";
  ## 查询下一条 ##
  next;
  }
  if (/^descr:/) {
  ## 由于文件中多条descr记录会导致重复记录，所以必须确保唯一性 ##
  our %desctime;
  $desctime{$recordline}++;
  next if ($desctime{$recordline} > 1);  ## 如果descr多条记录，直接跳过 ##
#  print "$desctime{$recordline}\n";
  ## 拼接 $descr 使其成为唯一的变量名字 ##
  our $descr = "$recordline" . "descr";
  ## 赋值散列值为当前行 ##
  $iprecord{$descr} = "$_";
  ## 查询此行是否包含条件关键字 这里用上海 ##
  if ( $iprecord{$descr} =~ /(Shanghai|ShangHai|shanghai|SHANGHAI)/ ){
     ## 生成临时变量，与之前的比较 ##
     my $inetnum_test = "$recordline" . "inet";
     if ($inetnum eq $inetnum_test){
#     print "$iprecord{$inetnum}\n";
     ## 将符合条件的记录写入数组 ##
     push (@finalrecord, "$iprecord{$inetnum}");
     }
  }
  next;
  }
  next;
}
close $somefile;

## Save to file ##
print "保存查询内容到$filetosave\n";
select $filesave;
foreach (@finalrecord){
  print "$_\n";
}
close $filesave
