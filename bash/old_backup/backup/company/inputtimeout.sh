#!/bin/sh


read -p "Please INPUT,[Default is 12345,timeout=10] : " -t 10 input01 

if [ "$?" -eq 1 ];then
input01='12345'
fi

echo "$input01"

