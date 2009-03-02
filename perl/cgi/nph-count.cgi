#!/usr/bin/perl -wT

use strict;

print "$ENV{SERVER_PROTOCOL} 200 OK\n";
print "Server: $ENV{SERVER_SOFTWARE}\n";
print "Content-type: text/plain\n\n";

print "OK, starting time consuming process ... \n";

# Tell Perl not to buffer our output
$| = 1;

for ( my $loop = 1; $loop <= 30; $loop++ ) {
    print "Iteration: $loop\n";
    ## Perform some time consuming task here ##
    sleep 1;
}

print "All Done!\n";
