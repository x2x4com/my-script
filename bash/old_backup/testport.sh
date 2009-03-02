#!/bin/bash
#HOST="localhost"
#PORT="25"

read -p "HOST=" HOST
read -p "PORT=" PORT
telnet ${HOST} ${PORT} >/dev/null 2>&1 <<EOF

quit
EOF
if [ $? -ne 0 ]
then
echo ${HOST}:${PORT} can not connect to
else
echo ${HOST}:${PORT} is ok
fi
