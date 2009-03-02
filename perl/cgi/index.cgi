#!/usr/bin/perl -wT

use strict;

my $time        = localtime;
my $remote_id   = $ENV{REMOTE_HOST} || $ENV{REMOTE_ADDR};
my $admin_email = $ENV{SERVER_ADMIN};

print "Content-type: text/html\n\n";

print <<END_OF_PAGE;
<HTML>
<HEAD>
  <TITLE>Welcome to Mike's Mechanics Database</TITLE>
</HEAD>

<BODY BGCOLOR="#ffffff">
  <IMG SRC="/images/mike.jpg" ALT="Mike's Mechanics">
  <P>Welcome from $remote_id! What will you find here? You'll
    find a list of mechanics from around the country and the type of
    service to expect -- based on user input and suggestions.</P>
  <P>What are you waiting for? Click <A HREF="/cgi/list.cgi">here</A>
    to continue.</P>
  <HR>
  <P>The current time on this server is: $time.</P>
  <P>If you find any problems with this site or have any suggestions,
    please email <A HREF="mailto:$admin_email">$admin_email</A>.</P>
</BODY>
</HTML>
END_OF_PAGE

