#!/usr/bin/perl


open F, "<production.log";
while (<F>) {
if (/^Processing\s*([^#]+)#\w+\s*\(for/) {
		print "$1 , $2 , $3\n";
}
}
