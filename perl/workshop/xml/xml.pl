#!/usr/bin/perl
#

use strict;
use IO::File;
use XML::Simple;

#my $fh = IO::File->new('exp.xml');
my $xml = new XML::Simple;

my $data = $xml->XMLin('book.xml');

use Data::Dumper;

print Dumper($data);

