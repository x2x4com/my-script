#!/usr/bin/perl -w

use CGI;
use strict;
#use Encode;
use DBI;
use CGI::Carp qw(fatalsToBrowser);  #debug

my $default = 0;
my $dic_file = '/home/jacky/scripts/git/my-script/perl/english/dic.txt';
my $tmp = '/tmp/english';
$| = 1;
my $db_name="english";
my $location="localhost";
my $port_num="3306";
my $db="DBI:mysql:$db_name:$location:$port_num;mysql_socket=/var/run/mysqld/mysqld.sock";
my $db_user="root";
my $db_passwd="root";


my $q = new CGI;

print $q->header(-charset=>'utf-8'),
$q->start_html("学习");

&head;

sub head {
	print $q->h1({-align=>'center'},'英语学习'),
	$q->hr();
}

sub foot {
	print <<'END_HTML'
<hr>
<table cellpadding="0" cellspacing="0" border="0" valign="middle" width="100%">
	<tr>
		<td width="50%" align="left"><a href="english.pl" title="返回默认页">首页</a></td>
		<td width="50%" align="right">Jacky Xu</td>
	</tr>
</table>
END_HTML
}

##  _es 文件由input_default (type=2创建)为input_post创建(type=1)
##  _ei 文件由start_exam完成测试后(exam)为input_default创建(type=2)
sub input_post {
	##将单词写入数据库
	my ($key,$key1,$word,$symbol,$trans,$w_type,$synonym,$antonym,$example) = @_;
	##print "$key<br>$word<br>$symbol<br>$trans<br>$w_type<br>$synonym<br>$antonym<br>$example";
	my ($key_failed,$local_key);
	open KEY, "$tmp/${key}._es" or $key_failed = 1;
	unless ($key_failed) {
		#print "<br>FILE OPENED<br>";
		foreach (<KEY>){
			chomp;
			$local_key = $_;
			#print "$local_key <br>";
		}
		$key_failed = 1 unless ( $key == $local_key);
		#print "$key_failed<br>";
		close KEY;
		unlink glob "$tmp/*._es" or $key_failed = 1;
		#print "$key_failed<br>";
	}
	unless ($key_failed) {
		my $dbh=DBI->connect($db,$db_user,$db_passwd) or my $db_fail = 1;
	#my $db_fail = 1;
		if ($db_fail) {
			print $q->p({-align=>'center'},"无法连接数据库");
		} else {
			my $rows = $dbh->do("INSERT INTO words (word,symbol,trans,type,synonym,antonym,example) VALUES (\"$word\",\"$symbol\",\"$trans\",\"$w_type\",\"$synonym\",\"$antonym\",\"$example\")");
			print $q->p("$word保存成功");
		}
	$dbh->disconnect();
	input_default($key1);
	} else {
		unlink glob "$tmp/*._es";
		print "<p>输入点错误，请不要恶意提交</p>";
	}
}

sub input_default {
	##如果已经是通过状态(有key值)，开始输入单词
	my ($key) = shift;
	my ($key_failed,$local_key);
	open KEY, "$tmp/${key}._ei" or $key_failed = 1;
	unless ($key_failed) {
		#print "<br>FILE OPENED<br>";
		foreach (<KEY>){
			chomp;
			$local_key = $_;
			#print "$local_key <br>";
		}
		$key_failed = 1 unless ( $key == $local_key);
		#print "$key_failed<br>";
		close KEY;
		#unlink glob "$tmp/*._ei" or $key_failed = 1;
		#print "$key_failed<br>";
	}

	unless ($key_failed) {
		my @source = (0..9,'a'..'z','A'..'Z');
		my $rand_key;
		for (my $i=0;$i<16;$i++) {
        	$rand_key .= $source[int (rand @source)];
		}
		my $open_failed;
		if ( ! -d $tmp ) {
			mkdir $tmp or $open_failed = 1;
		}
		unless ($open_failed) {
			open R_F, ">$tmp/${rand_key}._es" or $open_failed = 1;
		}
		unless ($open_failed) {
			print R_F "$rand_key";
			print <<HTML_OFF ;
	<form action="english.pl" method="post">
<p>必填字段<br>
<input type="hidden" name="type" value="2" />
<input type="hidden" name="key" value="$rand_key" />
<input type="hidden" name="key1" value="$key" />
 单词: <input type="text" name="word" value="" style='width:15%' />
 音标: <input type="text" name="symbol" value="" style='width:15%' />
 中文翻译: <input type="text" name="trans" value="" style='width:15%' />
 请选择词型: <select name="w_type">
	<option value="n" default>n 名词
	<option value="adj">adj 形容词
	<option value="v">v 动词
	<option value="adv">adv 副词
	<option value="vt">vt 及物动词
	<option value="vi">vi 不及物动词
	<option value="pron">pron 代名词
	<option value="num">num 数词
	<option value="art">art 冠词
	<option value="prep">prep 介词
	<option value="conj">conj 动词
	<option value="int">int 感叹词
	<option value="s">s 主词
	<option value="sc">sc 主词补语
	<option value="o">o 受词
	<option value="oc">oc 受词补语
	<option value="aux">aux 助动词
	<option value="c">c 可数
	<option value="pl">pl 复数
	<option value="abbr">abbr 缩写
</select>
<br><br>
可选字段,如有多值，请用&nbsp;;&nbsp;隔开<br>
同义词: <input type="text" name="synonym" value="" style='width:20%' />
反义词: <input type="text" name="antonym" value="" style='width:20%' />
<br>
例句:<BR>
<TEXTAREA ROWS=5 name="example" value="" style='width:60%'></TEXTAREA>
</p>
<table cellpadding="0" cellspacing="0" border="0" valign="center" width="20%">
<tr align="left" valign="middle">
<td valign="top">
<input type="submit" name="Submit" value="保存" />
</form>
</td>
<td valign="middle">&nbsp;&nbsp;&nbsp;&nbsp;</td>
<td valign="top">
<form action="english.pl" method="post">
<input type="hidden" name="type" value="0" />
<input type="submit" name="Submit" value="结束保存" />
</form>
</td>
</tr>
</table>
HTML_OFF

			close (R_F);
		} else {
			print "<p>无法创建key文件，请检查$tmp是否可写</p>";
		} 
} else {
	print <<EOF ;
				必须测试才能输入新单词<br>
					<form action="english.pl" method="post">
						<input type="hidden" name="type" value="5" />
						<input type="submit" name="Submit" value="开始测试" />
					</form>
EOF
}
}

sub query_default {
	#查询所有单词
	my $dbh=DBI->connect($db,$db_user,$db_passwd) or my $db_fail = 1;
	if ($db_fail) {
		print $q->p({-align=>'center'},"无法连接数据库");
	} else {
		my $sql = $dbh->prepare("select * from words");
		my $result = $sql->execute();
		print $q->p("单词库中共有$result个单词");
			my $id = 1;
			my @data;
			print  <<'EOF' ;
<table cellpadding="0" cellspacing="0" border="1" valign="left" width="100%">
			<tr align="center">
			<td>序号</td>
			<td>单词</td>
    			<td>音标</td>
    			<td>中文</td>
    			<td>类型</td>
    			<td>同义词</td>
    			<td>反义词</td>
    			<td>例句</td>
    		</tr>
EOF
			while(my $ref = $sql->fetchrow_hashref()) {
				$data[$id] = {};
				$data[$id]->{'word'} = $ref->{'word'};
    			$data[$id]->{'symbol'} = $ref->{'symbol'};
    			$data[$id]->{'trans'} = $ref->{'trans'};
    			$data[$id]->{'type'} = $ref->{'type'};
    			$data[$id]->{'synonym'} = $ref->{'synonym'};
    			$data[$id]->{'antonym'} = $ref->{'antonym'};
    			$data[$id]->{'example'} = $ref->{'example'};
    			print <<EOF ;
			<tr>
			<td>&nbsp;&nbsp;${id}&nbsp;&nbsp;</td>
			<td>$data[$id]->{'word'}</td>
    			<td>$data[$id]->{'symbol'}</td>
    			<td>$data[$id]->{'trans'}</td>
    			<td>$data[$id]->{'type'}</td>
    			<td>$data[$id]->{'synonym'}</td>
    			<td>$data[$id]->{'antonym'}</td>
    			<td>$data[$id]->{'example'}</td>
    			</tr>	
EOF
    			$id++;
			}
			print "</table>";
	$dbh->disconnect();
	}
}

sub query_post {
	#查询指定单词
	print "<P>未开发</p>";
	
}

sub pre_exam {
	#测试题准备，选择测试的数量
	my ($test_num) = @_;
	if (! defined $test_num) {
		print <<'END_HTML'
<p>
	<form action="english.pl" method="post">
		<input type="hidden" name="type" value="5" />
		请选择测试单词的数量(默认为单词总量的30%)
		<select name="test_num">
			<option value="0.3" default>30%
			<option value="0.1">10%
			<option value="0.2">20%
			<option value="0.4">40%
			<option value="0.5">50%
			<option value="0.6">60%
			<option value="0.7">70%
			<option value="0.8">80%
			<option value="0.9">90%
			<option value="1">100%
		</select>
		<input type="submit" name="Submit" value="提交" />
	</form>
</p>
END_HTML
	} else {
	#从系统中取出所有记录随机选择测试的数量，写入习题库
	my $dbh=DBI->connect($db,$db_user,$db_passwd) or my $db_fail = 1;
	my (@data,$score,$number);
	if ($db_fail) {
		print $q->p({-align=>'center'},"无法连接数据库");
	} else {
		my $sql = $dbh->prepare("select * from words");
		my $total = $sql->execute();
		if ((defined $total) && ($total != '0E0')) {
			$number = int($total*$test_num);
			$number = 1 if ($number == 0);
			print "<p>单词库中共有$total个单词，你必须要通过$number个单词</p>";
			my $id = 0;
			my ($score,$rows);
			while(my $ref = $sql->fetchrow_hashref()) {
				$data[$id] = {};
				$data[$id]->{'word'} = $ref->{'word'};
    			$data[$id]->{'symbol'} = $ref->{'symbol'};
    			$data[$id]->{'trans'} = $ref->{'trans'};
    			$data[$id]->{'type'} = $ref->{'type'};
    			$data[$id]->{'synonym'} = $ref->{'synonym'};
    			$data[$id]->{'antonym'} = $ref->{'antonym'};
    			$data[$id]->{'example'} = $ref->{'example'};
    			$id++;
			}
			$sql = $dbh->prepare("select * from exam");
			my $exam_stats = $sql->execute();
			if ($exam_stats != '0E0') {
				$dbh->do("delete from exam");	
			}
			for (my $i=0;$i<$number;$i++){
				my $tmp = $i + 1;
				my $rand_num = int(rand $id);
				#print $data[$rand_num]->{'word'} . "<br>";
				$rows += $dbh->do("INSERT INTO exam (id,word,symbol,trans,type,synonym,antonym,example) VALUES (\"$tmp\",\"$data[$rand_num]->{'word'}\",\"$data[$rand_num]->{'symbol'}\",\"$data[$rand_num]->{'trans'}\",\"$data[$rand_num]->{'type'}\",\"$data[$rand_num]->{'synonym'} \",\"$data[$rand_num]->{'antonym'}\",\"$data[$rand_num]->{'example'}\")");
				#print $rows . <br>;
			}
			if ($rows == $number) {
				print <<EOF ;
					<form action="english.pl" method="post">
						<input type="hidden" name="exam" value="" />
						<input type="hidden" name="c" value="1" />
						<input type="hidden" name="t" value="$rows" />
						<input type="submit" name="Submit" value="开始测试" />
					</form>
EOF
			} else {
				print <<EOF ;
				准备习题时发生错误(插入数据与测试数量不符合)<br>
					<form action="english.pl" method="post">
						<input type="hidden" name="type" value="5" />
						<input type="submit" name="Submit" value="返回测试首页" />
					</form>
EOF
			}
		} else {
			print "<p>数据库无记录或查询出错</p>";
		}
	$dbh->disconnect();
	}
	}
}

sub start_exam {
	my ($current,$total,$last_word) = @_;
	my $dbh=DBI->connect($db,$db_user,$db_passwd) or my $db_fail = 1;
	if ($db_fail) {
		print $q->p({-align=>'center'},"无法连接数据库");
	} else {
		if ($current <= $total) {
			unless ($current == 1){
				#查看上次单词是否正确
				my $last = $current - 1;
				my $sql = $dbh->prepare("select * from exam where id=\"$last\"");
				my $tmp = $sql->execute();
				#print "<h1>$tmp</h1>";
				my ($word,$trans,$score);
				while(my $ref = $sql->fetchrow_hashref()) {
					$word = $ref->{'word'};
					$trans = $ref->{'trans'};
				}
				print "第$last题结果:<br>";
				if ( $last_word =~ /^$word$/ ){
					print "回答正确，你的答案是: $last_word，正确答案是: $word<br>";
					$dbh->do("update exam set score='1' where id=\"$last\"");
				} else {
					print "回答错误，你的答案是: $last_word，正确答案是: $word<br>";
				}
			}
			#从数据库中拿出指定记录
			my $sql = $dbh->prepare("select * from exam where id=\"$current\"");
			my $row = $sql->execute();
			if ($row == 1) {
				my $trans;
				while(my $ref = $sql->fetchrow_hashref()) {
					$trans = $ref->{'trans'};
				}
				my $next = $current + 1;
				print <<EOF
				<p>第$current题: <br>
					<form action="english.pl" method="post">
						<input type="hidden" name="exam" value="" />
						<input type="hidden" name="c" value="$next" />
						<input type="hidden" name="t" value="$total" />
						$trans : <input type="text" name="w" value="" style='width:20%' />
						<input type="submit" name="Submit" value="下一题" />
					</form>
				</p>
EOF
			} else {
				my $next = $current + 1;
				print <<EOF ;
				系统错误，无法从数据库中取得指定数据<br>
					<form action="english.pl" method="post">
						<input type="hidden" name="exam" value="" />
						<input type="hidden" name="c" value="$next" />
						<input type="hidden" name="t" value="$total" />
						<input type="hidden" name="w" value="null" />
						<input type="submit" name="Submit" value="下一题" />
					</form>
EOF
			}
		} elsif (($current - $total) == 1 ) {
			#习题结束，开始评分
			#答对90%才能算通过
			#查看上次单词是否正确
			my $last = $current - 1;
			my $sql = $dbh->prepare("select * from exam where id=\"$last\"");
			my $tmp = $sql->execute();
			#print "<h1>$tmp</h1>";
			my ($word,$trans,$score);
			while(my $ref = $sql->fetchrow_hashref()) {
					$word = $ref->{'word'};
					$trans = $ref->{'trans'};
			}
			print "第$last题结果:<br>";
			if ( $last_word =~ /^$word$/ ){
				print "回答正确，你的答案是: $last_word，正确答案是: $word<br>";
				$dbh->do("update exam set score='1' where id=\"$last\"");
			} else {
				print "回答错误，你的答案是: $last_word，正确答案是: $word<br>";
			}
			my $next = $current + 1;
			print <<EOF ;
					<form action="english.pl" method="post">
						<input type="hidden" name="exam" value="" />
						<input type="hidden" name="c" value="$next" />
						<input type="hidden" name="t" value="$total" />
						<input type="hidden" name="w" value="" />
						<input type="submit" name="Submit" value="点击完成测试" />
					</form>
EOF
		} else {
			my $sql = $dbh->prepare("select * from exam where score='1'");
			my $row = $sql->execute();
			$row = 0 if ($row eq '0E0');
			my $pass = int ($total * 0.9);
			print "根据系统规定，答对90%才能算通过<br>本次总题目数量为$total";
			if (( $row >= $pass ) && ($row != 0)) {
				my $open_failed;
				if ( ! -d $tmp ) {
					mkdir $tmp or $open_failed = 1;
				}
				my @source = (0..9,'a'..'z','A'..'Z');
				my $rand_key;
				for (my $i=0;$i<16;$i++) {
        			$rand_key .= $source[int (rand @source)];
				}
				unless ($open_failed) {
					unlink glob "$tmp/*._ei";
					open R_F, ">$tmp/${rand_key}._ei" or $open_failed = 1;
				}
				unless ($open_failed) {
					print R_F "$rand_key";
					print <<EOF ;
				，你答对了$row，通过了测试<br>
					<form action="english.pl" method="post">
						<input type="hidden" name="type" value="1" />
						<input type="hidden" name="key" value="$rand_key" />
						<input type="submit" name="Submit" value="添加新单词" />
					</form>
EOF
				close R_F;
			} else {
					print "<p>无法创建key文件，请检查$tmp是否可写</p>";
			}
			} else {
				print <<EOF ;
				，你答对了$row，没有达到标准<br>
					<form action="english.pl" method="post">
						<input type="hidden" name="type" value="5" />
						<input type="submit" name="Submit" value="返回测试首页" />
					</form>
EOF
			}
		}
	$dbh->disconnect();
	}
}

#type list
# 1 input default
# 2 input post
# 3 query default
# 4 query post
# 5 pre_exam

##  _es 文件由input_default (type=2创建)为input_post创建(type=1)
##  _ei 文件由start_exam完成测试后(exam)为input_default创建(type=2)

if ($q->param) {
	if ($q->param('type') == 1 ) {
		my $key = $q->param('key');
		#if (($key =~ /\w+/ ) && (defined $pass)){
		input_default($key);	
		#} else {
		#	print $q->p({-align=>'center'},'提交有误');
		#}
	} elsif ($q->param('type') == 2 ) {
		if ( ($q->param('key') =~ /^\w+/ ) && ($q->param('word') =~ /^\w+/ ) && ($q->param('symbol')  =~ /^.*/ ) && ($q->param('trans') =~ /^\w+/ ) && ($q->param('w_type') =~ /^\w+/ )) {
			my $word = $q->param('word');
			my $symbol = $q->param('symbol');
			my $trans = $q->param('trans');
			my $w_type = $q->param('w_type');
			my $key = $q->param('key');
			my $key1 = $q->param('key1');
			my $synonym =  $q->param('synonym') || 'null';
			my $antonym =  $q->param('antonym') || 'null';
			my $example =  $q->param('example') || 'null';
			input_post($key,$key1,$word,$symbol,$trans,$w_type,$synonym,$antonym,$example);
		} else {
			print $q->p({-align=>'center'},'提交有误');
		}
	} elsif ($q->param('type') == 3 ) {
		&query_default;
	} elsif ($q->param('type') == 4 )  {
		&query_post;
	} elsif ($q->param('type') == 5 )  {
		pre_exam($q->param('test_num'));
	} elsif (defined $q->param('exam'))  {
		if (($q->param('c') =~ /^\d+$/) && ($q->param('t') =~ /^\d+$/ ) ){ ## && ( $q->param('c') <= $q->param('t')) ){
			start_exam($q->param('c'),$q->param('t'),$q->param('w'));
		} else {
			print $q->p({-align=>'center'},'进入点错误','c = ', $q->param('c'),'t = ' , $q->param('t'));
		}
	} elsif ($q->param('type') == 0 ) {
		$default = 1;
	} else {
		print $q->p({-align=>'center'},'请求错误');
	} 
} else {
	$default = 1;
}

if ($default) {
	unlink glob "$tmp/*._es";
	unlink glob "$tmp/*._ei";
	print << 'END_HTML'
<P>	   
	<a href="english.pl?type=1" title="输入单词">输入单词</a>
	<br>
	<a href="english.pl?type=3" title="显示单词库">显示单词库</a>
	<!--br-->
	<!--a href="english.pl?type=4" title="查询修改单词">查询修改单词</a-->
	<br>
	<a href="english.pl?type=5" title="单词测试">单词测试</a>
</P> 
END_HTML
}

&foot;

print $q->end_html();

