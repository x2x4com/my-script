#!/bin/bash
#
# Squid blacklist maintenance script
# Author: Jacky.xu@livebytouch.com
# Create-Date: 2007-11-18
# Last-Change-Date: Never

##ȷ���������ļ�
file="/etc/squid/denydomain.list"
##�������
domain=$2
if [ ! -z $domain ];then
checklist
checkrecordnum=`cat $file | grep $domain| wc -l`
fi
if [ -z $confirm ];then
confirm=
fi
if [ -z $mrecord ];then
mrecord=
fi
if [ -z $inputdomainname ];then
inputdomainname=
fi
if [ -z $checkagain ];then
checkagain=
fi


##����-����Ƿ��б�������
function checkdomain () {
        if [ -z $domain ];then
                        echo "Usage : `basename $0` {add | del} domainname"
                                echo "Usage : `basename $0` show"
                                echo "Usage : `basename $0` {listdel | search} keyword"
                exit 0
	fi
}

##����-����¼����
function checkrecordnum () {
        if [ $checkrecordnum -lt 1 ];then
                echo "We have not any record like $domain in $file"
                exit 0
	fi
}

##����-���������ļ��Ƿ����
#check file
function checklist(){
	if [ ! -f $file ];then
		echo "Error! $file not exist !!  Please modify this script and setup file path"
		exit 0
	fi
}

##����-���
function add() {
	checklist
	checkdomain
	##����¼���Ƿ�С��1,С��1ֱ����ӡ�������Ҫ�û�����ȷ�ϲ������
	if [ $checkrecordnum -lt 1 ];then
		echo "$domain" >> $file
	else
		echo "Warning! Find $checkrecordnum record like $domain in $file"
		echo "List likely record:"
		more $file| grep $domain
		echo "Do you confirm to add $domain?"
		##���confirm����
		confirm=
		while [ -z $confirm ]
		do
		echo -n "y/n: "
		read confirm
		done
			if [ ${confirm} = y ];then
				echo "$domain" >> $file
			else
				echo "Nothing to do...Exit"
				exit 0
			fi
	fi

}

##����ɾ��##
function delete() {
	checklist
	checkdomain
	checkrecordnum
  if [ $domain == `cat $file | grep ^${domain}$` ];then
                echo "Do you confim to delete record $domain?"
		confirm=
		while [ -z $confirm ]
		do
                echo -n "y/n: "
                read confirm
		done
                        if [ ${confirm} = y ];then
				###����봫��shell������sed��""##
				##�����Ҫ��ȷƥ�� exp:sed '/^www.sina.com$/d' ufile�� ^����ͷ  $����β ����ͬ���������� grep
				sed -i "/^${domain}$/d" $file 
                                echo "delete record $domain"
                        fi
		else
			echo "Sorry, no record find, please checkout and try again"
			delete_inputnew
		fi
}



function delete_inputnew() {
                            echo "Please input full domain name which you want to delete."
                            while [ -z $inputdomainname ]
                            do
                            echo -n "Domain name: "
                            read inputdomainname
                            done
                            checkagain=`cat $file | grep $inputdomainname | wc -l`
			    if [ -z $checkagain ];then
				echo "Sorry, no record find, please checkout and try again"
				exit 0
			    fi
			    	if [ $inputdomainname == `cat $file | grep ^${inputdomainname}$` ];then
                            		echo "Do you confim to delete record $inputdomainname?"
					confirm=
					while [ -z $confirm ]
					do
                                	echo -n "y/n: "
                                	read confirm
					done
                                	if [ $confirm = y ];then
						sed -i "/^${inputdomainname}$/d" $file
                                		echo "delete record $inputdomainname"
					else 
						echo "Noting to do...Exit!"
					fi
				else
					echo "Sorry, no record find, please checkout and try again"
			   	fi
}

function delete_more_main() {
		checklist
        	checkdomain
                echo "Find $checkrecordnum record like $domain in $file"
                echo "List likely record:"
                more $file| grep $domain
                echo "Do you want to delete them one by one?"
		confirm=
		while [ -z $confirm ]
		do
                echo -n "y/n: "
                read confirm
		done
                        if [ $confirm = y ];then
				delete_mrecord
                        elif [ $confirm = n ];then
				delete_inputnew
			else
                             echo "Nothing to do...Exit"
                             exit 0
                        fi
}


function delete_mrecord() {
           for mrecord in `cat $file| grep $domain`
           do
           echo "Do you confim to delete record $mrecord?"
					 confirm=
					 while [ -z $confirm ]
					 do
           echo -n "y/n: "
           read confirm
					 done
           if [ ${confirm} = y ];then
							sed -i "/^${mrecord}$/d" $file
              echo "$mrecord had been deleted"
						else
							echo "Keep $mrecord in list"
           fi
           done
}




function show() {
	checklist
	more $file

}

function search() {
        checklist
	checkdomain
	checkrecordnum
        cat $file| grep $domain

}

function reloadsquid() {
	/etc/init.d/squid reload
}

case "$1" in
    "add")
	add
        echo "$2 had been added to $file"
        ;;

    "del")
        delete
        ;;

    "show")
        show
        ;;

    "search")
        search
        ;;
       
    "listdel")
        delete_more_main
        ;; 
        
    *)
	echo "============================================="
    	echo "This is a Squid blacklist maintenance script."
	echo "============================================="
        echo "Usage : `basename $0` {add | del} domainname"
				echo "Usage : `basename $0` show"
				echo "Usage : `basename $0` {listdel | search} keyword"
				echo " "
				echo "exp : `basename $0` add www.abc.com"
				echo "exp : `basename $0` del www.abc.com"
				echo "exp : `basename $0` search abc"
				echo "exp : `basename $0` listdel abc"
        exit 0
        ;;
esac

