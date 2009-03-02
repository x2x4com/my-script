VA_HOME=/usr/java/j2sdk1.4.2_12
CLASSPATH=$JAVA_HOME/lib:$JAVA_HOME/jre/lib
PATH=$PATH:$HOME/bin:$JAVA_HOME/bin

export JAVA_HOME CLASSPATH PATH


echo `date` >> /root/scrpit/auto_restart_tc.log

for i in `ps -ef | grep tomcat | grep java | grep -v grep | awk '{print $2}'`
do
echo "Tomcat PID=$i Will be kill" >> /root/scrpit/auto_restart_tc.log
kill -9 $i
done

echo `date` >> /root/scrpit/auto_restart_tc.log



sudo -u tomcat /usr/local/tomcat/tomcat/bin/startup.sh

for i in `ps -ef | grep tomcat | grep java | grep -v grep | awk '{print $2}'`
do
echo "Tomcat New PID=$i" >> /root/scrpit/auto_restart_tc.log
done
