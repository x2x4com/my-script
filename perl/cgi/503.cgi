#!/usr/bin/perl -wT


print <<END_OF_HTML;
Status: 503 Database Unavailable
Content-type: text/html

<HTML>
<HEAD><TITLE>503 Database Unavailable</TITLE></HEAD>
<BODY>
  <H1>Error</H1>
  <P>Sorry, the database is currently not available. Please
    try again later.</P>
</BODY>
</HTML>
END_OF_HTML
