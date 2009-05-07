#!/bin/bash
# This script run at 00:00

# The Nginx logs path
logs_path="/usr/local/webserver/nginx/logs/"

mkdir -p ${logs_path}$(date -d "yesterday" +"%Y")/$(date -d "yesterday" +"%m")/
mv ${logs_path}access.log ${logs_path}$(date -d "yesterday" +"%Y")/$(date -d "yesterday" +"%m")/access_$(date -d "yesterday" +"%Y%m%d").log
kill -USR1 `cat /usr/local/webserver/nginx/nginx.pid`
