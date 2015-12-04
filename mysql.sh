#!/bin/sh
#!/bin/sh

ip=$1
file=/usr/local/xrender/sh/xrender_docker20151201.sql

docker_host_ip_old=10.22.200.18
docker_host_ip_new=$ip
sed_strings="
$docker_host_ip_old##${docker_host_ip_new}
"
mysql -uroot -e"grant all on *.* to 'root'@'%' identified by 'xrender' with grant option; grant all on *.* to xrender@'%' identified by 'xrender';flush privileges;"
for sed_item in $sed_strings ; do 
    sed_from=`echo $sed_item | awk -F'##' '{print $1}'`
    sed_to=`echo $sed_item | awk -F'##' '{print $2}'`
    sed -i "s/$sed_from/$sed_to/g"  $file
done
mysql -h$ip -uxrender -pxrender -e 'create database xrender'
mysql -h$ip -uxrender -pxrender xrender < $file

exit 0
