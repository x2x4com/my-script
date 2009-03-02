#!/bin/bash

if [ $UID -ne 0 ];then
echo "You are not root" && exit 99
fi

if [ ! -f "Config.pm" ];then
echo "Miss Config.pm" && exit 99
fi

chown root:root Config.pm

perl_version=`perl -v | grep "This is perl, v" | cut -d " " -f 4 | cut -d "v" -f 2`
#echo $perl_version

cp Config.pm /usr/lib/perl5/$perl_version/CPAN/.
if [ $? -ne 0 ];then
echo "Copy fail" && exit 99
fi

echo "Auto install Perl Modules"

perl -MCPAN -e "install Authen::SASL"
if [ $? -ne 0 ];then
echo "Install Authen::SASL fail, Please run: perl -MCPAN -e \"install Authen::SASL\""
fi
perl -MCPAN -e "install Net::SMTP_auth"
if [ $? -ne 0 ];then
echo "Install Net::SMTP_auth fail, Please run: perl -MCPAN -e \"install Net::SMTP_auth\""
fi
perl -MCPAN -e "install MIME::Lite"
if [ $? -ne 0 ];then
echo "Install MIME::Lite fail, Please run: perl -MCPAN -e \"install MIME::Lite\""
fi
