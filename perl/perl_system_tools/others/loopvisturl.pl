#!/usr/bin/perl

use File::Basename;
$scriptbase = basename $0;
$curl = '/usr/bin/curl';

if (@ARGV < 2) {
	die "��������!\nʹ�÷�����$scriptbase ���ʴ��� ���ʵ�Ŀ��\n";
}

-x $curl or die "�޷�ִ��$curl�� $!\n";

$runtimes = shift;

if ( $runtimes =~ /\d+/ ){
for ($i=1;$i<$runtimes+1;$i++) {
print "��$i�η���\n";
print "$ARGV[0]\n";
	if (system $curl, "-o","/tmp/tmpvist", "$ARGV[0]") {
		die "��$ARGV[0]ʧ��,runtime = $i\n";
	}
unlink "/tmp/tmpvist" or warn "�޷�ɾ����ʱ�ļ�\n";
}
} else { 
	die "���ʴ����������\n";
}
