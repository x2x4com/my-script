#!/usr/bin/perl


my $recordline = 0;
my %iprecord;
my @finalrecord;

## ���������� ##
if (defined $ARGV[0]) {
  chomp (our $filename = $ARGV[0]);
} else { 
  print "�������ѯ�ļ�����";
  chomp (our $filename = <STDIN>);
}

## ���������� ##
if (defined $ARGV[1]) {
  chomp (our $filetosave = $ARGV[1]);
} else {
  print "������Ҫ�����ѯ���ݵ��ļ���";
  chomp (our $filetosave = <STDIN>);
}

## ��Ŀ���ļ� ##
open $somefile,$filename or die "�޷���Ŀ���ļ�$filename : $!\n";
## �򿪱����ѯ���ݵ��ļ� ##
open $filesave, ">$filetosave" or die "�޷��򿪱����ļ�$filetosave: $!\n";

foreach (<$somefile>) {
## ��׽ֱ�ӻ���,�������������$recordline�Լ�1��Ȼ��ֱ�Ӳ�ѯ��һ�� ##
  if (/^.$/s){
    $recordline++;
    next;
  }
## ��׽inetnum�ֶ� ##
  if (/^inetnum:/){
  ## ƴ�� $inetnum ʹ���ΪΨһ�ı������� ##
  our $inetnum = "$recordline" . "inet";
  ## ɾ�� $_ �Ļس��� ##
  chomp;
  ## ��ֵɢ��$iprecord{$inetnum}ֵΪ��ǰ��##
  $iprecord{$inetnum} = "$_";
  ## ��ѯ��һ�� ##
  next;
  }
  if (/^descr:/) {
  ## �����ļ��ж���descr��¼�ᵼ���ظ���¼�����Ա���ȷ��Ψһ�� ##
  our %desctime;
  $desctime{$recordline}++;
  next if ($desctime{$recordline} > 1);  ## ���descr������¼��ֱ������ ##
#  print "$desctime{$recordline}\n";
  ## ƴ�� $descr ʹ���ΪΨһ�ı������� ##
  our $descr = "$recordline" . "descr";
  ## ��ֵɢ��ֵΪ��ǰ�� ##
  $iprecord{$descr} = "$_";
  ## ��ѯ�����Ƿ���������ؼ��� �������Ϻ� ##
  if ( $iprecord{$descr} =~ /(Shanghai|ShangHai|shanghai|SHANGHAI)/ ){
     ## ������ʱ��������֮ǰ�ıȽ� ##
     my $inetnum_test = "$recordline" . "inet";
     if ($inetnum eq $inetnum_test){
#     print "$iprecord{$inetnum}\n";
     ## �����������ļ�¼д������ ##
     push (@finalrecord, "$iprecord{$inetnum}");
     }
  }
  next;
  }
  next;
}
close $somefile;

## Save to file ##
print "�����ѯ���ݵ�$filetosave\n";
select $filesave;
foreach (@finalrecord){
  print "$_\n";
}
close $filesave
