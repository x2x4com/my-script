#!/usr/bin/perl

sub dbcount{
 my $db_name="DBname";
 my $location="hostname";
 my $port_num="3306";
 my $db="DBI:mysql:$db_name:$location:$port_num".";mysql_socket=/tmp/mysql.sock";
 my $db_user="root";
 my $db_passwd="password";
 my $dbh=DBI->connect($db,$db_user,$db_passwd) or print_error("Can not connect to database!");
 return ($dbh);
}

my $dbh=dbcount();

my $dbh=dbcount();
my $sql=$dbh->prepare("some sql");
my  $result=$sql->execute();
