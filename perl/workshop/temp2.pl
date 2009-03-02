#!/usr/bin/perl

use Net::SSH qw(ssh issh sshopen2 sshopen3 ssh_cmd);

my $host = '192.168.1.12';
my $user = 'jacky';
my $pass = 'sandy5xu';
my $cmd = 'ls -lrt';

ssh_cmd( {
          user => "$user",
          host => "$host",
          command => 'ls',
          args => ['-l','-a','-t','-r'],
          });
