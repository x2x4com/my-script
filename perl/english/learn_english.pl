#!/usr/bin/perl

use strict;
use Data::Dumper;
#use Time::HiRes qw(time);

my $dic_file = '/home/jacky/scripts/git/my-script/perl/english/dic.txt';
$| = 1;

my  (@last_words,$day);
#===============================#

sub read_stdin {
	my ($print_w,$default) = @_;
	my $loop = 1;
	my $word;
	while ($loop){
		print $print_w;
		$word = <STDIN>;
		chomp $word;
		if ($word =~ /^\s*$/){
			if ($default != 1){
				$word = $default;
				$loop = 0;
			}
		} else {
			$loop = 0;
		}
	}
	return $word;	
}

sub input_words {
	my $day = shift;
	open SAVE, ">>$dic_file";
	print SAVE "#$day\n";
	my @new_words;
	my $loop = 1;
	while ($loop) {
		my $word = read_stdin("请输入单词: ","1");
		my $word_c = read_stdin("请输入$word中文含义: ","1");
		my $word_t = read_stdin("请输入$word类型:(n,v,adv,adj...etc) ","null");
		my $word_s = read_stdin("请输入$word的同义词: ","null");
		my $word_d = read_stdin("请输入$word的反义词: ","null");
		my $example = read_stdin("请输入$word的例句: ","null");
		print SAVE "|$word|$word_c|$word_t|$example|$word_s|$word_d|\n";
		my $quit = read_stdin("任意键输入下一个单词，退出输入请键入q : ","n");
		$loop = 0 if ($quit =~ /^[q|Q]/);	
	}
	close (SAVE);
}

sub get_last_words{
	my $day;
	open LOAD, "<$dic_file";
	foreach (<LOAD>) {
		if (/^#(\d+)\s*$/){
			$day = $1;
			@last_words = ();
			next;
		}
		chomp;
		push @last_words, $_;
	}
	close (LOAD);
	return $day;
}

sub my_test {
	my $type = shift;
	if ($type =~ /^all$/){
		print "下面将随机选取单词库中一定数量(总量的10%)的单词测试\n";
		open LOAD, "<$dic_file";
		my %words;
		my $i = 1;
		foreach (<LOAD>) {
			my ($word,$word_c,$word_d,$word_s,$word_t);
			$words{$i} = {};
			if (/^\|(.*)\|(.*)\|(.*)\|(.*)\|(.*)\|(.*)\|\s*\r?\n?$/) {
				$words{$i}->{'word'} = $1;
				$words{$i}->{'word_c'} = $2;
				$words{$i}->{'word_t'} = $3;
				$words{$i}->{'example'} = $4;
				$words{$i}->{'word_s'} = $5;
				$words{$i}->{'word_d'} = $6;
			}
			$i++;
		}
		print "当前单词总量为$i\n";
		print "你需要回答" . int(($i-1)*0.1) . "题\n";
		for (my $ii=0;$ii<int(($i-1)*0.1);$ii++) {
			my $r = int (rand $i);
			print "第" . ($ii+1) . "题\n" . $words{$r}->{'word_c'} . ":  ";
			my $waitting = <STDIN>;
			if ($waitting eq $words{$r}->{'word'} ) {
				print "回答正确\n";
			} else { 
				print "回答错误，正确答案是: " . $words{$r}->{'word'} . "\n";
			}
			print $words{$r}->{'word'} . "例句: \n" . $words{$r}->{'example'} . "\n同义词有: " . $words{$r}->{'word_s'} . "\n反义词有: " . $words{$r}->{'word_d'} . "\n";
		}
	} elsif ($type =~ /^last$/) {
		print "你好，下面将测试上次所学习的单词，中译英\n";
		my $score = 0;
		foreach (@last_words) {
			if (/^\|(.*)\|(.*)\|(.*)\|(.*)\|(.*)\|(.*)\|\s*\r?\n?$/) {
				print "$2 : ";
				my $answer = <STDIN>;
				chomp $answer;
				if ( "$answer" eq "$1" ) {
					print "回答正确\n";
					$score++;
				} else {
					print "回答错误，正确答案是: $1 ;你的答案是: $answer\n";
				}
				print "$1 的使用例句: $4\n同义词有: $5\n反义词有: $6\n";
			}
		}
		my $pass = int (@last_words * 0.9);
		die "你答对了$score题，系统规定必须答对$pass才能通过测试，请复习后重新测试\n" if ($score < $pass);
	}
}

if (! -f $dic_file) {
	my $time_before = time;
	print "你好，你是第一次使用，程序将会为你创建$dic_file，请不要删除此文件\n";
	input_words(1);
	print "本次学习结束，共花时" . (time - $time_before)/60 . "分钟\n";
} else {
	my $time_before = time;
	$day = &get_last_words + 1;
	if ($day > 1) {
		my_test("last");
		my_test("all");
		input_words($day);
		print "本次学习结束，共花时" . (time - $time_before)/60 . "分钟\n";
	} else {
		print "你好，你是第一次使用，程序将会为你创建$dic_file，请不要删除此文件\n";
		input_words(1);
		print "本次学习结束，共花时" . (time - $time_before)/60 . "分钟\n";
	}
}
	
