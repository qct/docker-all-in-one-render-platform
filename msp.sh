#!/bin/sh
ip=$1
sed -i "s/10.22.200.18/$ip/g" /usr/local/apache-tomcat-6.0.44/webapps/msp-web/WEB-INF/classes/system.properties
kill -9 $(pidof java)
/usr/local/apache-tomcat-6.0.44/bin/startup.sh
exit 0
