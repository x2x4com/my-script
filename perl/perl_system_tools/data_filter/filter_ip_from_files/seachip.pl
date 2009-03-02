#!/usr/bin/perl

my @data_source,$datafile,$source,@data_match;
my $dt = 0;
if (! defined $ARGV[0] ){
	die "useage : command filename\n";
}

$source = $ARGV[0];

open $datafile, $source or die "Can not open $source, $!\n";

while (<$datafile>){
	if (/^\s*$/){
		#print "@{$data_fragment}\n";
		#sleep (1);
		$dt++;
		$data_fragment = "data_fragment_$dt";
		#print "$data_fragment\n";
		next;
	}
	push @{$data_fragment}, $_;
	#push @data_source, [@{$data_fragment}];
}

for (my $i=0;$i<$dt;$i++){
	$data_fragment = "data_fragment_$i";
	if ( ${$data_fragment}[2] =~ /^descr:.*(Shanghai|ShangHai|shanghai|SHANGHAI).*/ ){
		if ( ${$data_fragment}[0] =~ /^inetnum:/ ){
			push @data_match, ${$data_fragment}[0];
			next;
		}
		next;
	} elsif ( ${$data_fragment}[3] =~ /^descr:.*(Shanghai|ShangHai|shanghai|SHANGHAI).*/ ) {
		if ( ${$data_fragment}[0] =~ /^inetnum:/ ){
                        push @data_match, ${$data_fragment}[0];
                        next;
                }
                next;
	}
	next;
}

print "@data_match\n";
