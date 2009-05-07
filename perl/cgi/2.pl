#!/usr/bin/perl

use CGI;
use strict;
use CGI::Session;


my $q = new CGI;

my $session = new CGI::Session("driver:File", $q ,{Directory=> , '/tmp/session'});

my $strName = $session->param("name");



print $q->header(); 



print $q->start_html();
print "-------------------$strName--------------------\n"; 



print $q->end_html();


__END__

       find(), will automatically remove expired sessions. Following example will remove all the objects that are 10+
       days old:

           CGI::Session->find( \&purge );
           sub purge {
               my ($session) = @_;
               next if $session->is_empty;    # <-- already expired?!
               if ( ($session->ctime + 3600*240) <= time() ) {
                   $session->delete() or warn "couldn't remove " . $session->id . ": " . $session->errstr;
               }
           }

       Note: find will not change the modification or access times on the sessions it returns.


or use

 To store session data in MySQL database, you first need to create a suitable table for it with the following command:

    CREATE TABLE sessions (
        id CHAR(32) NOT NULL UNIQUE,
        a_session TEXT NOT NULL
    );
$session = new CGI::Session( "driver:mysql", $sid, {Handle=>$dbh} );
