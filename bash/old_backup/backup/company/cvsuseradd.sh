#!/bin/sh
###################################
#				  #	
# create cvs user		  #
#				  #
# ver 0.5	Jacky.xu	  #
#				  #	
#				  #
###################################




#passwdgen_path=/home/cvsroot
#cvs_root=/home/cvsroot
#cvs_passwd_file=$cvs_root/CVSROOT/passwd
#cvs_clean_passwd_file=$cvs_root/CVSROOT/passwd_1
cvs_user_name="cvsroot"
passwdgen_path=`pwd`
cvs_root=`pwd`
cvs_passwd_file=`pwd`/CVSROOT/passwd
cvs_clean_passwd_file=`pwd`/CVSROOT/passwd_1
if [ ! -z $2 ];then
user=$2
fi
if [ ! -z $3 ];then
pass1=$3
fi

function test_file {

if [ ! -d $cvs_root/CVSROOT ];then
	echo "$cvs_root/CVSROOT not find"
	echo "Prompt: cvs -d $cvs_root init"
	exit 99
fi

if [ ! -f $cvs_passwd_file ];then
	echo "$cvs_passwd_file not find, auto create now"
	touch $cvs_passwd_file
	if [ $? -ne 0 ];then
		echo "Create $cvs_passwd_file faile"
		exit 99
	fi
fi
if [ ! -f $cvs_clean_passwd_file ];then
	echo "$cvs_clean_passwd_file not find, auto create now"
	touch $cvs_clean_passwd_file
	if [ $? -ne 0 ];then
		echo "Create $cvs_clean_passwd_file faile"
		exit 99
	fi
fi

if [ ! -x $passwdgen_path/passwdgen.pl ];then
echo "$passwdgen_path/passwdgen.pl not find, or not executable"
echo "Create new one"

echo '#!/usr/bin/perl' >$passwdgen_path/passwdgen.pl
echo 'srand (time());' >> $passwdgen_path/passwdgen.pl
echo 'my $randletter = "(int (rand (26)) + (int (rand (1) + .5) % 2 ? 65 : 97))";' >> $passwdgen_path/passwdgen.pl
echo 'my $salt = sprintf ("%c%c", eval $randletter, eval $randletter);' >> $passwdgen_path/passwdgen.pl
echo 'my $plaintext = shift; my $crypttext = crypt ($plaintext, $salt);' >> $passwdgen_path/passwdgen.pl
echo 'print "${crypttext}\n";' >> $passwdgen_path/passwdgen.pl

echo "make $passwdgen_path/passwdgen.pl executable"
chmod +x $passwdgen_path/passwdgen.pl
fi 

}

function add_user() {
                        for i in `cat $cvs_passwd_file | cut -d ":" -f 1`
                        do
                        user_1=$i
                        if [ "$user" = "$user_1" ];then
                                echo "User:$user_1 exist, please check "
                                exit
                        fi
                        done

                        echo -n "Create Password for ${user}: "
                        stty -echo 
                        read pass1
                        stty echo 
			echo
                        echo -n "Retype Password for ${user}: "
                        stty -echo 
                        read pass2
                        stty echo
			echo 

                        if [ "$pass1" = "$pass2" ];then
                                pass3=`$passwdgen_path/passwdgen.pl $pass1`
                                echo "$user:$pass3:$cvs_user_name" >> $cvs_passwd_file
                                echo "$user:$pass1" >> $cvs_clean_passwd_file
                                echo "User:$user Create succeed"
                        else
                                echo "Sorry, passwords do not match"
                                exit

                        fi

}

function mod_user() {
			sea_user
			if [ -z $pass1 ];then
				echo "But lost new password, please check help file"
				help
				exit
			fi
                        sed -i '/^'$user':/d' $cvs_passwd_file
                        sed -i '/^'$user':/d' $cvs_clean_passwd_file
                        pass3=`$passwdgen_path/passwdgen.pl $pass1`
                        echo "$user:$pass3:$cvs_user_name" >> $cvs_passwd_file
                        echo "$user:$pass1" >> $cvs_clean_passwd_file
                        echo "$user password had been reset"
			echo "$user new password is $pass1"
}

function sea_user() {
                find_user=`cat $cvs_clean_passwd_file | egrep '^'$user':'`
		if [ -z $find_user ];then
			echo "User:$user not find"
			exit
		fi
		echo "List find user"
		echo $find_user
}


function list_user() {
		echo "List all User:"
		sn_1=1
		for username in `cat $cvs_clean_passwd_file | cut -d ":" -f 1`
		do
		echo "$sn_1 : $username"
		let sn_1=$sn_1+1
		done
}

function del_user() { 
		
		sea_user
		echo -n "Do your want to delete $user ? [yes/no] (default is no)"
		read confirm_del
		if [ "$confirm_del" = "yes" ];then
			sed -i '/^'$user':/d' $cvs_passwd_file
			sed -i '/^'$user':/d' $cvs_clean_passwd_file
			echo "User:$user deleted"
		else
			echo "Must input \"yes\" to confirm, exit now"
			exit
		fi
}


function help() { 
	        echo "Useage `basename $0` add | mod | del | search | list all | help"
                echo ""
                echo "add - add user"
		echo "exp: `basename $0` add username"
                echo ""
                echo "mod - modify user password"
		echo "exp: `basename $0` mod username newpassword"
                echo ""
		echo "del - delete user"
		echo "exp: `basename $0` del username"
                echo ""
                echo "search - looking for user password"
		echo "exp: `basename $0` search username"
                echo ""
		echo "list - list all user"
		echo "exp: `basename $0` list all"
		echo ""
                echo "help - help page"	
}

if [ $# -lt 2 ];then
	help
	exit 99
fi

case $1 in 
	add) 	
		test_file
		add_user
		;;
	mod)
		test_file
		mod_user
		;;
	del)	
		test_file
		del_user
		;;
	search)	
		test_file
		sea_user
		;;
	list)
		test_file
		list_user
		;;
	help)	
		help
		;;
	*)	
		help
		;;
esac
