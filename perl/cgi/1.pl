#!/usr/bin/perl

use CGI;
use strict;
use CGI::Session;



my $q = new CGI;

my $session = new CGI::Session("driver:File", $q , {Directory=> , '/tmp/session'});
my $cookie = $q->cookie(CGISESSID => $session->id );

print $q->header(-cookie=> $cookie);

$session->param('name', $session->id);

$q->start_html("学习");

print "<script language='javascript'>;";

print " location.href='2.pl';";

print "</script>;";


print $q->end_html();
