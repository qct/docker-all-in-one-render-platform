#!/bin/sh
ip=$1
file=/home/ftp1/script/condor_base.py

docker_host_ip_old=10.22.200.18
docker_host_ip_new=$ip
sed_strings="
$docker_host_ip_old##${docker_host_ip_new}
"

for sed_item in $sed_strings ; do 
    sed_from=`echo $sed_item | awk -F'##' '{print $1}'`
    sed_to=`echo $sed_item | awk -F'##' '{print $2}'`
    sed -i "s/$sed_from/$sed_to/g" $file
done

exit 0