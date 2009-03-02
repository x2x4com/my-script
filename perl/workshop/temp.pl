#!/usr/bin/perl

use Net::SSH::Perl;

my $host = '192.168.1.12';
my $user = 'jacky';
my $pass = 'sandy5xu';
my $cmd = 'cat /etc/passwd';

my $ssh = Net::SSH::Perl->new($host);
$ssh->login($user, $pass);
my($stdout, $stderr, $exit) = $ssh->cmd($cmd);

print "STDOUT = $stdout
STDERR = $stderr
EXIT CODE = $exit\n";
