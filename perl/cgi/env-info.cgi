#!/usr/bin/perl -wT

use strict;

my %env_info = (
    SERVER_SOFTWARE     => "the server software",
    SERVER_NAME         => "the server hostname or IP address",
    GATEWAY_INTERFACE   => "the CGI specification revision",   
    SERVER_PROTOCOL     => "the server protocol name",
    SERVER_PORT         => "the port number for the server",
    REQUEST_METHOD      => "the HTTP request method",
    PATH_INFO           => "the extra path info",
    PATH_TRANSLATED     => "the extra path info translated",
    DOCUMENT_ROOT       => "the server document root directory",
    SCRIPT_NAME         => "the script name",
    QUERY_STRING        => "the query string",
    REMOTE_HOST         => "the hostname of the client",
    REMOTE_ADDR         => "the IP address of the client",
    AUTH_TYPE           => "the authentication method",
    REMOTE_USER         => "the authenticated username",
    REMOTE_IDENT        => "the remote user is (RFC 931): ",
    CONTENT_TYPE        => "the media type of the data",
    CONTENT_LENGTH      => "the length of the request body",
    HTTP_ACCEPT         => "the media types the client accepts",
    HTTP_USER_AGENT     => "the browser the client is using",
    HTTP_REFERER        => "the URL of the referring page",
    HTTP_COOKIE         => "the cookie(s) the client sent"
);

print "Content-type: text/html\n\n";

print <<END_OF_HEADING;

<HTML>
<HEAD>
    <TITLE>A List of Environment Variables</TITLE>
</HEAD>

<BODY>
<H1>CGI Environment Variables</H1>

<TABLE BORDER=1>
  <TR>
    <TH>Variable Name</TH>
    <TH>Description</TH>
    <TH>Value</TH>
  </TR>
END_OF_HEADING

my $name;

# Add additional variables defined by web server or browser
foreach $name ( keys %ENV ) {
    $env_info{$name} = "an extra variable provided by this server"
        unless exists $env_info{$name};
}

foreach $name ( sort keys %env_info ) {
    my $info = $env_info{$name};
    my $value = $ENV{$name} || "<I>Not Defined</I>";
    print "<TR><TD><B>$name</B></TD><TD>$info</TD><TD>$value</TD></TR>\n";
}

print "</TABLE>\n";
print "</BODY></HTML>\n";

