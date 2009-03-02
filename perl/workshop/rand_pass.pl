#!/usr/bin/perl -w
use Tk;
use Tk::LabEntry;
use strict;


my $mw = MainWindow->new;
$mw->geometry("190x50");
$mw->title("Rand Password");

## default 
my $len_i = 8;

$mw->LabEntry(-label => "Enter passwd length: ",
              -labelPack => [ -side => "left" ],
              -textvariable => \$len_i)->pack();

my $button_frame = $mw->Frame()->pack(-side => "bottom");

$button_frame->Button(-text => "Ok",
                      -command => \&rand_pass )->pack(-side => "left");
$button_frame->Button(-text => "Exit",
                      -command => sub{exit})->pack(-side => "left");

sub rand_pass {
	unless ( $len_i =~ /\d+/ ) {
		$mw->messageBox(-message => "Input error" );
		goto RAND_END;
	}

	my @source = (0..9,'$','a'..'z','A'..'Z','+');
	my $password;
	for (my $i=0;$i<$len_i;$i++) {
        $password .= $source[int (rand @source)];
	}
	#$mw->messageBox(-message => "$password");
	my $subwin = $mw->Toplevel;
	$subwin->title("Password");
	$subwin->LabEntry(-label => "passwd: ",
              -labelPack => [ -side => "left" ],
              -textvariable => \$password)->pack();
	#$subwin->Button(-text => "Exit", -command => sub{return;} )->pack(-side => "bottom");
	RAND_END:
}

MainLoop;
