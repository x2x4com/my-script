#!/usr/bin/perl

#**********************************************************
#
# Script Name:   monitor_center
# Script Author: jacky.xu@serversupport.cn
# Created Date:  2008-10-23
# Function desc:  It's Jacky Perl Monitor System Main Code
#				  Start Monitor by config_files
#				  This is Master Monitor Side
#
# Script Usage:  monitor_center -c config_file
#
# Script Needs:  logserver 
#				 sendmail.pl 
#				 sms.pl 
#				 monitor_center.conf
#
#**********************************************************


use strict;
use Thread;
use File::Basename;
use POSIX qw(strftime);
use IO::Socket;
use Net::Ping;
#use POSIX qw(WNOHANG);

my $script_name = basename $0;
my $script_dir = dirname $0;
my $config = {};
my ($config_file,$service_config,$global_config);

sub useage {
	die "  Useage : $script_name -c config\n";
}

if ( (@ARGV == 2) && ($ARGV[0] eq '-c') ){
	$config_file = $ARGV[1];
} else {
	useage();
}

open CONFIG, "<$config_file" or die "Can not open config file, $!\n";
foreach (<CONFIG>) {
	next if (/^#.*/);
	chomp $_;
	if (/^\[(Global)\]/) {
		$global_config = 1;
		next;
	} elsif (/^\[(Service)(\d+)\]/){
		$global_config = 0;
		$service_config = $2;
		next;
	} elsif (/^.*=.*/) {
		if ( $global_config == 1 ) {
			my ($key,$value) = split /\s*=\s*/, $_;
			$config->{"global"}->{$key} = $value;
			#print "global->$key = $value\n";
			next;
		} elsif ( $service_config =~ /(\d+)/) {
			my ($key,$value) = split / *= */, $_;
			$config->{"service$1"}->{$key}=$value;
			#print "service$1->$key = $value\n";
			next;
		}
	} else { next;}
}

## Here we check config file ##
## Check global config ##
die "Config check error in Global, socket_timeout\n" unless ( $config->{"global"}->{"socket_timeout"} =~ /^\d+$/ );
die "Config check error in Global, log_server_ip\n" unless ( $config->{"global"}->{"log_server_ip"} =~ /^([1-9]|[1-9]\d|1\d{2}|2[01]\d|22[0-3])(\.(\d|[1-9]\d|1\d{2}|2[0-4]\d|25[0-5])){3}$/);
die "Config check error in Global, log_server_port\n" unless ( ($config->{"global"}->{"log_server_port"} > 0) && ($config->{"global"}->{"log_server_port"} < 65536) );
die "Config check error in Global, mail_proc\n" unless ( -x $config->{"global"}->{"mail_proc"} );
die "Config check error in Global, mail_user\n" unless ( $config->{"global"}->{"mail_user"} =~ /^\w+([\.|-|_]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+(,\w+([\.|-|_]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+)*$/);
die "Config check error in Global, mail_pass\n" unless (defined $config->{"global"}->{"mail_pass"});
#die "Config check error in Global, mail_to\n" unless ( $config->{"global"}->{"mail_to"} =~ /^(\w+([\.|-|_]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+(,\w+([\.|-|_]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+)*)(,\w+([\.|-|_]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+(,\w+([\.|-|_]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+)*)*$/ );
#die "Config check error in Global, mail_cc\n" unless ( $config->{"global"}->{"mail_cc"} =~ /^(\w+([\.|-|_]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+(,\w+([\.|-|_]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+)*)(,\w+([\.|-|_]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+(,\w+([\.|-|_]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+)*)*$/ );

die "Config check error in Global, mail_to\n" unless ( $config->{"global"}->{"mail_to"} =~ /^(.*\@.*)(,.*\@.*)*$/);
die "Config check error in Global, mail_cc\n" unless ( $config->{"global"}->{"mail_cc"} =~ /^(.*\@.*)(,.*\@.*)*$/);
die "Config check error in Global, mail_from\n" unless ( defined $config->{"global"}->{"mail_from"} );
die "Config check error in Global, sms_proc\n" unless ( -x $config->{"global"}->{"sms_proc"} );
die "Config check error in Global, sms_to\n" unless ( $config->{"global"}->{"sms_to"} =~ /^\d{11}(,\d{11})*$/ );
die "Config check error in Global, mail_smtp_server\n" unless ( defined $config->{"global"}->{"mail_smtp_server"} );



## Check service config ##
for ( my $i=1;$i<=$service_config;$i++ ) {
	$i = sprintf("%02d",$i);
	die "Config check error in Service$i, service_name\n" unless ($config->{"service$i"}->{"service_name"} =~ /^[-_.a-zA-Z0-9]+$/);
	die "Config check error in Service$i, communication_key\n" unless ($config->{"service$i"}->{"communication_key"} =~ /^\w+$/);
	die "Config check error in Service$i, target_ip\n" unless ($config->{"service$i"}->{"target_ip"} =~ /^([1-9]|[1-9]\d|1\d{2}|2[01]\d|22[0-3])(\.(\d|[1-9]\d|1\d{2}|2[0-4]\d|25[0-5])){3}$/);
	die "Config check error in Service$i, target_port\n" unless ( ($config->{"service$i"}->{"target_port"} > 0) && ($config->{"service$i"}->{"target_port"} < 65536) );
	die "Config check error in Service$i, monitor_sleeptime\n" unless ($config->{"service$i"}->{"monitor_sleeptime"} =~ /^\d+$/);
	die "Config check error in Service$i, monitor_port\n" unless ( ($config->{"service$i"}->{"monitor_port"} > 0) && ($config->{"service$i"}->{"monitor_port"} < 65536) );
	die "Config check error in Service$i, monitor_server_ping\n" unless ($config->{"service$i"}->{"monitor_server_ping"} =~ /^[1|0]$/);
	#die "Config check error in Service$i, monitor_type\n" unless ($config->{"service$i"}->{"monitor_type"} =~ /^[1|2]$/)
	if ($config->{"service$i"}->{"monitor_type"} == 2) {
		die "Config check error in Service$i, monitor_return_keyword\n" unless ($config->{"service$i"}->{"monitor_return_keyword"} =~ /^(.*)$/);
		die "Config check error in Service$i, monitor_socket_send_words\n" unless (defined $config->{"service$i"}->{"monitor_socket_send_words"});
	} else {
		die "Config check error in Service$i, monitor_type\n" unless ($config->{"service$i"}->{"monitor_type"} == 1);
	}
	die "Config check error in Service$i, monitor_socket_connect_timeout\n" unless ($config->{"service$i"}->{"monitor_socket_connect_timeout"} =~ /^(\d+)$/);
	die "Config check error in Service$i, monitor_fail_command\n" unless (defined $config->{"service$i"}->{"monitor_fail_command"});
	die "Config check error in Service$i, monitor_fail_action\n" unless ($config->{"service$i"}->{"monitor_fail_action"} =~ /^[1-7]$/);
}

## Check finish ##
#print "All config check sucess\n";

## defind time format ##
my $time_format = sub { my $time_now = POSIX::strftime("\[%Y-%m-%d %H:%M:%S\]", localtime(time));return $time_now;};
my $yymmdd = sub { my $time_now = POSIX::strftime("%Y-%m-%d", localtime(time));return $time_now;};
## defind time format over ##


## Start Log Server ##
sub logserver {
	(-x "$script_dir/log_center") or die "Can not start log server\n$script_dir/log_center: $!\n";
    my $log_dir = dirname $config->{"global"}->{"global_logfile"};
    my $log_file = basename $config->{"global"}->{"global_logfile"};
	system "$script_dir/log_center",$config->{"global"}->{"log_server_port"},$config->{"global"}->{"socket_timeout"},$log_dir,$log_file;
}
## Start Log Server over ##

## monitor type sub ##
sub mon_t_1 {
	my ($my_ip,$my_port,$timeout) = @_;
	#print "$my_ip,$my_port,$timeout\n";
	my $socket;
	eval {
	$socket = IO::Socket::INET->new(PeerAddr => "$my_ip",
                					PeerPort => "$my_port",
                					Proto => 'tcp',
                					Type => SOCK_STREAM,
                					Timeout => "$timeout") or die "$!\n";
	};
	if ($@) {
		#print "$@\n";
    	return 0;  ## 0 is fail
	} else {
    	close($socket);
    	return 1;   ##  1 is ok
	}
}

sub mon_t_2 {
	my ($my_ip,$my_port,$send,$timeout,$keys_words) = @_;
	my ($socket,$findkeys,@socket_answer);
	eval{
		$socket = IO::Socket::INET->new(PeerAddr => "$my_ip",
										PeerPort => "$my_port",
										Proto => 'tcp',
										Type => SOCK_STREAM,
										Timeout => "$timeout") or die "$my_ip:$my_port die\n";
	};
	if ($@ =~ /$my_ip:$my_port die/){
		return 0; ## 0 is die
	} else {
		$SIG{ALRM} = \&time_out;
		print $socket "$send\n";
		eval{
			alarm (30);
			@socket_answer = <$socket>;
			close ($socket);
			alarm (0);
		};
		sub time_out { die "Timeout\n" };
		if ( $@ =~ /Timeout/ ) {
			close ($socket);
			return 0;
		} else {
			foreach (@socket_answer){
			$findkeys = 0;
			if (/$keys_words/){
				$findkeys = 1;
				last;
			} else { next;}
			}
			if ($findkeys){
				return 1;
			} else {
				return 0;
			}
		}
	}
}

## monitor type sub over ##

sub send_mail {
	my ($sub,$messages) = @_;
	$sub = "$config->{global}->{mail_from} $sub";
	system $config->{"global"}->{"mail_proc"},"server:$config->{global}->{mail_smtp_server}","user:$config->{global}->{mail_user}","pass:$config->{global}->{mail_pass}","to:$config->{global}->{mail_to}","cc:$config->{global}->{mail_cc}","from:$config->{global}->{mail_from}","sub:$sub","message:$messages";
}

sub send_sms {
	my ($message_tosend) = @_;
	system "$config->{global}->{sms_proc}","$config->{global}->{sms_to}","$message_tosend";
}

sub do_action {
	my ($target_ip,$target_port,$service_name,$communication_key,$fail_command,$port) = @_;
	#print "$target_ip,$target_port,$service_name,$communication_key,$fail_command\n";
	my $tmp_service_name = $service_name;
	my ($new_salt,$answer,@answers,$socket,$exec_return,@fail_details);
	my $new_salt = sub { my $salt = join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64]; return $salt; };
	#print $new_salt->() . "\n";
	$service_name = crypt ($service_name,$new_salt->());
	$communication_key = crypt ($communication_key,$new_salt->());

	eval {
	$socket = IO::Socket::INET->new( PeerAddr => $target_ip,
                                    PeerPort => $target_port,
       	                            Proto    => 'tcp')
            	    or die "Can't connect $target_ip:$target_port\n";
	};
	
	if ( $@ =~ /^Can't connect $target_ip:$target_port/ ) {
		#print "Client: $target_ip:$target_port connect fail\n";
		#return 0; ## 0 is fail
		my $tmp_1 = $@ ;
		my $tmp_2 = "Status:$@";
		to_logserver($tmp_2);
		to_err_log($target_ip,$port,$tmp_service_name,$tmp_2);
		return $tmp_1;
	} else {
		$socket->autoflush(1);
		chomp ($answer = <$socket>);
		if ( "$answer" eq "service_name:" ) {
    		print $socket "$service_name\n";
    		chomp ($answer = <$socket>);
    		if ( "$answer" eq "keys:" ) {
        		print $socket "$communication_key\n";
        		chomp ($answer = <$socket>);
        		if ("$answer" eq "ok,go ahead") {
            		print $socket "$fail_command\n";
            		@answers = <$socket>;
            		#print "@answers\n";
            		close $socket;
					foreach my $s_r (@answers) {
						next if ( $s_r =~ /^\s*$/ );
						if ( $s_r =~ /^\s*(.*)\s*$/ ) {
							if ( $1 =~ /^exec_return=\s*(.*)\s*$/ ) {
								$exec_return = $1;
							} else {
								#print "$1\n";
								push @fail_details,$1;
								my $tmp_msg = "Client:${target_ip}:$target_port Return:$1";
								to_logserver($tmp_msg);
								to_err_log($target_ip,$port,$tmp_service_name,$1);
							}
						}
						next;
					}
					if ( $exec_return == 0 ) {
                    	my $tmp_msg = "Client:${target_ip}:$target_port Exec_status:Sucess";
                    	to_logserver($tmp_msg);
						to_err_log($target_ip,$port,$tmp_service_name,$tmp_msg);
                    	return 1; ## 1 is ok
                    } else {
                    	my $tmp_msg = "Client:${target_ip}:$target_port Exec_status:Fail";
                    	to_logserver($tmp_msg);
						to_err_log($target_ip,$port,$tmp_service_name,$tmp_msg);
                    	#return 0; ## 0 is bad
						return @fail_details;
                    }
        		} else {
					my $tmp_message = "Client:${target_ip}:$target_port Return:$answer";
           			#print "$tmp_message\n";
					to_logserver($tmp_message);
					to_err_log($target_ip,$port,$tmp_service_name,$tmp_message);
            		close $socket;
					#return 0;
					return $answer;
        		}
    		} else {
				my $tmp_message = "Client:${target_ip}:$target_port Return:$answer";
           		#print "$tmp_message\n";
 	       		to_logserver($tmp_message);
				to_err_log($target_ip,$port,$tmp_service_name,$tmp_message);
        		close $socket;
				#return 0;
				return $answer;
    		}
		} else {
			my $tmp_message = "Client:${target_ip}:$target_port Return:$answer";
           	#print "$tmp_message\n";
    		to_logserver($tmp_message);
			to_err_log($target_ip,$port,$tmp_service_name,$tmp_message);
    		close $socket;
			#return 0;
			return $answer;
		}
	}
}

sub to_logserver {
	my ($message_tosend) = @_;
	## Get Logserver ojb ##
	my $log_server = IO::Socket::INET->new( PeerAddr => $config->{"global"}->{"log_server_ip"} ,
											PeerPort => $config->{"global"}->{"log_server_port"},
											Proto    => 'tcp') or die "Can not connect to LogServer, $!\n";
	print $log_server "[Client Log] Host:". $ENV{"HOSTNAME"}." $message_tosend\n";
	close $log_server
}

sub to_err_log {
	my ($target_ip,$port,$service_name,$err) = @_;
	#print "$target_ip,$port,$service_name,$err\n";
	my $today = $yymmdd->();
	my $err_log;
	my $log_dir = dirname $config->{"global"}->{"global_logfile"};
	open $err_log,">>$log_dir/err_${today}_${target_ip}_${port}_${service_name}.log";
	print $err_log ""."$err\n";
	close $err_log;
}


## monitor sub ##
sub start_monitor {
	my $service_list = shift @_;
	## sleep ($service_list);
	## print "$service_list\n";
	my $monitor_type = shift @_;
	my $log_dir = dirname $config->{"global"}->{"global_logfile"};
	my ($send_words,$connect_timeout,$return_keys,$service_name,$communication_key,$target_ip,$target_port,$sleep_time,$port,$server_ping,$fail_command,$fail_action,$socket_return);
	if ($monitor_type == 2) {
		($send_words,$connect_timeout,$return_keys,$service_name,$communication_key,$target_ip,$target_port,$sleep_time,$port,$server_ping,$fail_command,$fail_action) = @_;
		## print "Monitor Type is 2\n$return_keys,$service_name,$communication_key,$target_ip,$target_port,$sleep_time,$port,$server_ping,$fail_command,$fail_action\n";
	} elsif ($monitor_type == 1) {
		($connect_timeout,$service_name,$communication_key,$target_ip,$target_port,$sleep_time,$port,$server_ping,$fail_command,$fail_action) = @_;
		## print "Monitor Type is 1\n$service_name,$communication_key,$target_ip,$target_port,$sleep_time,$port,$server_ping,$fail_command,$fail_action\n";
	}
	$fail_command .= ' 2>&1 ; echo exec_return=$?';
	## print "redo faild_command, $fail_command\n";
	while (1) {
		my $ok_log;
		my $today = $yymmdd->();
		open $ok_log,">>$log_dir/ok_${today}_${target_ip}_${port}_${service_name}.log";
		if ($monitor_type == 1) {
			#print "$target_ip,$port\n";
			$socket_return = mon_t_1($target_ip,$port,$connect_timeout);
		} elsif ($monitor_type == 2) {
			$socket_return = mon_t_2($target_ip,$port,$send_words,$connect_timeout,$return_keys);
		}
		unless ($socket_return) {
			my ($message_body,$log_body);
			if ($server_ping) {
				my $p = Net::Ping->new();
				if ( $p->ping($target_ip, 2) ) {
        			$log_body = "Service:$service_name Target:$target_ip:$port Status:Socket(Get or Connect)->Fail,Ping->OK";
					$message_body = "<b>System diagnose</b>: <br>Socket(Get or Connect from $port) is fail but Ping $target_ip is ok";
				} else {
        			$log_body = "Service:$service_name Target:$target_ip:$port Status:Socket(Get or Connect)->Fail,Ping->Fail";
					$message_body = "<b>System diagnose</b>: <br>Socket(Get or Connect from $port) is fail and Ping $target_ip fail";
				}
				to_logserver($log_body);
				to_err_log($target_ip,$port,$service_name,$log_body);
				$p->close();
			} else {
				$log_body = "Service:$service_name Target:$target_ip:$port Status:Socket(Get or Connect)->Fail,Ping->Disable";
				$message_body = "<b>System diagnose</b>: <br>Socket(Get or Connect from $port) is fail (ping $target_ip is disable on config file)";
				to_logserver($log_body);
				to_err_log($target_ip,$port,$service_name,$log_body);
			}
			$message_body = "<b>System Time</b>: <BR>" . $time_format->() ."<BR><b>IP & Port</b>:<BR>$target_ip:$port<BR><b>Service</b>:<BR>$service_name<BR>" . $message_body . "<BR><b>The list command will run</b>:<br>$fail_command<br>";
			## Fail action type list
            # 1 sendmail
            # 2 sendsms
            # 3 sendmail+sendsms
            # 4 runcommand
            # 5 sendmail+runcommand
            # 6 sendsms+runcommand
            # 7 sendmail+sendsms+runcommand
			my $sub = "$target_ip:$port $service_name fail";
			my $send_errors = "<b>System Time</b>: <BR>" . $time_format->() ."<BR><b>IP & Port</b>:<BR>$target_ip:$port<BR><b>Service</b>:<BR>$service_name<BR><b>Running command</b>: <BR>$fail_command <BR><b>Return details</b>:";
			if ($fail_action == 7) {
				send_mail($sub,$message_body);
				send_sms($message_body);
                my @do_action_status = do_action($target_ip,$target_port,$service_name,$communication_key,$fail_command,$port);
                if ($do_action_status[0] == 1) {
                    my $sub = "$target_ip:$port $service_name failed action is running sucess";
                    my $message_body = "$send_errors <br>Action return is 1";
                    send_mail($sub,$message_body);
                } else {
                    foreach my $tmp_1 (@do_action_status) {
                        $send_errors = $send_errors . '<BR>' . $tmp_1;
                    }
                    my $sub = "$target_ip:$port $service_name failed action is running fail";
                    send_mail($sub,$send_errors);
                }
			} elsif ($fail_action == 6) {
				send_sms($message_body);
                my @do_action_status = do_action($target_ip,$target_port,$service_name,$communication_key,$fail_command,$port);
                if ($do_action_status[0] == 1) {
                    my $sub = "$target_ip:$port $service_name failed action is running sucess";
                    my $message_body = "$send_errors <br>Action return is 1";
                    send_mail($sub,$message_body);
                } else {
                    foreach my $tmp_1 (@do_action_status) {
                        $send_errors = $send_errors . '<BR>' . $tmp_1;
                    }
                    my $sub = "$target_ip:$port $service_name failed action is running fail";
                    send_mail($sub,$send_errors);
                }
			} elsif ($fail_action == 5) {
				send_mail($sub,$message_body);
				my @do_action_status = do_action($target_ip,$target_port,$service_name,$communication_key,$fail_command,$port);
				if ($do_action_status[0] == 1) {
					my $sub = "$target_ip:$port $service_name failed action is running sucess";
					my $message_body = "$send_errors <br>Action return is 1";
					send_mail($sub,$message_body);
				} else {
					foreach my $tmp_1 (@do_action_status) {
						$send_errors = $send_errors . '<BR>' . $tmp_1;
					}
					my $sub = "$target_ip:$port $service_name failed action is running fail";
					send_mail($sub,$send_errors);
				}
			} elsif ($fail_action == 4) {
                my @do_action_status = do_action($target_ip,$target_port,$service_name,$communication_key,$fail_command,$port);
                my $send_errors;
                if ($do_action_status[0] == 1) {
                    my $sub = "$target_ip:$port $service_name failed action is running sucess";
                    my $message_body = "Action return is 1";
                    send_mail($sub,$message_body);
                } else {
                    foreach my $tmp_1 (@do_action_status) {
                        $send_errors = $send_errors . '<BR>' . $tmp_1;
                    }
                    my $sub = "$target_ip:$port $service_name failed action is running fail";
                    send_mail($sub,$send_errors);
                }
			} elsif ($fail_action == 3) {
				$message_body = $message_body . "<BR><b>Fail command had been disabled</b>";
				send_mail($sub,$message_body);
				send_sms($message_body);
			} elsif ($fail_action == 2) {
				$message_body = $message_body . "<BR><b>Fail command had been disabled</b>";
				send_sms($message_body);
			} elsif ($fail_action == 1) {
				$message_body = $message_body . "<BR><b>Fail command had been disabled</b>";
				send_mail($sub,$message_body);
			}
			undef $sub;
		} else {
			print $ok_log "". $time_format->() . " $target_ip:$port $service_name is ok\n";
		}
		close $ok_log;
		sleep ($sleep_time);
	}
}
## monitor sub over ##



## Start Thread ##
my $t_logserver = Thread->new(\&logserver);
sleep (1);
my @t;
#print "$service_config\n";
for (my $ii=1;$ii<$service_config+1;$ii++){
	my $ii_f = sprintf("%02d",$ii);
	if ($config->{"service$ii_f"}->{"monitor_type"} == 2){
		$t[$ii] = Thread->new(\&start_monitor,$ii_f,$config->{"service$ii_f"}->{"monitor_type"},$config->{"service$ii_f"}->{"monitor_socket_send_words"},$config->{"service$ii_f"}->{"monitor_socket_connect_timeout"},$config->{"service$ii_f"}->{"monitor_return_keyword"},$config->{"service$ii_f"}->{"service_name"},$config->{"service$ii_f"}->{"communication_key"},$config->{"service$ii_f"}->{"target_ip"},$config->{"service$ii_f"}->{"target_port"},$config->{"service$ii_f"}->{"monitor_sleeptime"},$config->{"service$ii_f"}->{"monitor_port"},$config->{"service$ii_f"}->{"monitor_server_ping"},$config->{"service$ii_f"}->{"monitor_fail_command"},$config->{"service$ii_f"}->{"monitor_fail_action"});
	} elsif ($config->{"service$ii_f"}->{"monitor_type"} == 1){
		$t[$ii] = Thread->new(\&start_monitor,$ii_f,$config->{"service$ii_f"}->{"monitor_type"},$config->{"service$ii_f"}->{"monitor_socket_connect_timeout"},$config->{"service$ii_f"}->{"service_name"},$config->{"service$ii_f"}->{"communication_key"},$config->{"service$ii_f"}->{"target_ip"},$config->{"service$ii_f"}->{"target_port"},$config->{"service$ii_f"}->{"monitor_sleeptime"},$config->{"service$ii_f"}->{"monitor_port"},$config->{"service$ii_f"}->{"monitor_server_ping"},$config->{"service$ii_f"}->{"monitor_fail_command"},$config->{"service$ii_f"}->{"monitor_fail_action"});
	}
}
#print "Main Start Finish ... \n";
$t_logserver->join();
for (my $ii=1;$ii<$service_config+1;$ii++){
    $t[$ii]->join();
}
## Start Thread over ##
