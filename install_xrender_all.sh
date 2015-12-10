#!/bin/sh
# xrender All-In-One Installer
# Usage: sh install_xrender_all.sh base_dir
#DEBUG='y'

# if command failed then exit 
# set -e


XRENDE_INSTALL_ROOT=${XRENDE_INSTALL_ROOT:-"/usr/local/XRENDE"}

CENTOS6='CENTOS6'
CENTOS7='CENTOS7'
UBUNTU1404='UBUNTU14.04'
SUPPORTED_OS="$CENTOS6, $CENTOS7, $UBUNTU1404"
XRENDE_INSTALL_LOG='/tmp/XRENDE_installation.log'
OS=""
STEP="1"

[ -f $XRENDE_INSTALL_LOG ] && /bin/rm -f $XRENDE_INSTALL_LOG
INSTALLATION_FAILURE=/tmp/XRENDE_installation_failure_exit_code
[ -f $INSTALLATION_FAILURE ] && /bin/rm -f $INSTALLATION_FAILURE

BASE_DIR=`dirname $0`

[ ! -d $BASE_DIR ] && ( echo $BASE_DIR not exsist ; exit) 

cd $BASE_DIR
IP=$1
DOCKER_DATA_BASE="/usr/local/xrender/data/"
DOCKER_SH_BASE="/usr/local/xrender/sh/"

# The params is failed reason
fail(){
     #tput cub 6
     #echo -e "$(tput setaf 1) FAIL\n$(tput sgr0)"|tee -a $XRENDE_INSTALL_LOG
     #echo -e "$(tput setaf 1)    Reason: $*\n$(tput sgr0)"|tee -a $XRENDE_INSTALL_LOG
     echo "$*    \n\nThe detailed installation log could be found in $XRENDE_INSTALL_LOG " | tee -a  $INSTALLATION_FAILURE
     exit 1
}


LOG()
{
    echo -e '\n' >> $XRENDE_INSTALL_LOG
    echo $1 >> $XRENDE_INSTALL_LOG
}


echo_title(){
     echo -e "\n================">> $XRENDE_INSTALL_LOG
     echo ""|tee -a $XRENDE_INSTALL_LOG
     echo -n -e " ${STEP}. $*:\n" |tee -a $XRENDE_INSTALL_LOG
     STEP=`expr $STEP + 1`
}

echo_subtitle(){
     echo -e "\n----------------" >> $XRENDE_INSTALL_LOG
     echo -n -e "     $*:\n"|tee -a $XRENDE_INSTALL_LOG
}


#Do preinstallation checking for CentOS and Ubuntu
check_system(){
     echo_title "Check System"
     echo ""
     cat /etc/*-release |egrep -i -h "centos |Red Hat Enterprise" >>$XRENDE_INSTALL_LOG 2>&1
     if [ $? -eq 0 ]; then
            grep 'release 6' /etc/system-release >>$XRENDE_INSTALL_LOG 2>&1
            if [ $? -eq 0 ]; then
                OS=$CENTOS6
            else
                grep 'release 7' /etc/system-release >>$XRENDE_INSTALL_LOG 2>&1
                if [ $? -eq 0 ]; then
                     OS=$CENTOS7
                     rpm -q libvirt |grep 1.1.1-29 >/dev/null 2>&1
                     if [ $? -eq 0 ]; then
                            fail "Your OS is old CentOS7, as its libvirt is `rpm -q libvirt`. You need to use \`yum upgrade\` to upgrade your system to latest CentOS7."
                     fi
                else
                     fail "Host OS checking failure: your system is: `cat /etc/system-release`, we can only support $SUPPORTED_OS currently"
                fi
            fi
            which unzip >/dev/null 2>&1
            if [ $? -ne 0 ];then
                yum install -y unzip    >>$XRENDE_INSTALL_LOG 2>&1
            fi
     else
            grep 'Ubuntu 14.04' /etc/issue >>$XRENDE_INSTALL_LOG 2>&1
            if [ $? -eq 0 ]; then
                OS=$UBUNTU1404
            else
                fail "Host OS checking failure: your system is: `cat /etc/issue`, we can only support $SUPPORTED_OS currently"
            fi
            which unzip >/dev/null 2>&1
            if [ $? -ne 0 ];then
                apt-get install unzip    >>$XRENDE_INSTALL_LOG 2>&1
            fi
     fi
     
     LOG "Your system is: $OS"
}

install_package()
{
    echo_subtitle "install_package $1"
    package=$1
    whereis $package > /dev/null 2>&1
    [ "$?" = "0" ] && ( LOG "package $package is installed";return )
    if [ "$OS" = "$UBUNTU1404" ] ; then 
        apt-get install -y $package
    else
        yum install -y $package
    fi
}

# install docker
install_docker()
{
    echo_title "install_docker $@"
    install_package docker
    service docker start
}

# data dir  will be mounted to docker as application data 
install_data()
{
    echo_title "install_data"
    data_path=$BASE_DIR/data.tgz
    [ ! -f $data_path ] && (fail "$data_path not exist")
    
    mkdir -p $DOCKER_DATA_BASE
    tar -xzvf $data_path -C $DOCKER_DATA_BASE > /dev/null 2>&1
    chmod -R 777 $DOCKER_DATA_BASE > /dev/null 2>&1
}

# sh dir  will be mounted to docker and execute for change configure
install_sh()
{
    echo_title "install_sh"
    sh_path=$BASE_DIR/sh.tgz
    tar -czvf $sh_path *.sh *.sql > /dev/null 2>&1
    [ ! -f $sh_path ] && (fail "$sh_path not exist")
    
    mkdir -p $DOCKER_SH_BASE
    tar -xzvf $sh_path -C $DOCKER_SH_BASE > /dev/null 2>&1
    chmod -R 777 $DOCKER_SH_BASE > /dev/null 2>&1
}



# image path
declare -A docker_image_path=()
docker_image_path["portal"]=$BASE_DIR/portal.tar
docker_image_path["rabbitmq"]=$BASE_DIR/rabbitmq.tar
docker_image_path["condor"]=$BASE_DIR/condor.tar
docker_image_path["platform"]=$BASE_DIR/test-platform.tar
docker_image_path["msp"]=$BASE_DIR/test-msp.tar
docker_image_path["python"]=$BASE_DIR/python.tar
docker_image_path["redis"]=$BASE_DIR/redis.tar
docker_image_path["ftp"]=$BASE_DIR/ftp.tar
docker_image_path["mysql"]=$BASE_DIR/mysql.tar

     
# tag
declare -A docker_image_tag=()
docker_image_tag["portal"]="registry.local:5000/xrender-ax-test/portal"
docker_image_tag["rabbitmq"]="registry.local:5000/xrender-ax-test/rabbitmq"
docker_image_tag["condor"]="registry.local:5000/xrender-ax-test/condor"
docker_image_tag["platform"]="registry.local:5000/xrender-ax-test/test-platform"
docker_image_tag["msp"]="registry.local:5000/xrender-ax-test/test-msp"
docker_image_tag["python"]="registry.local:5000/xrender-ax-test/python"
docker_image_tag["redis"]="registry.local:5000/xrender-ax-test/redis"
docker_image_tag["ftp"]="registry.local:5000/xrender-ax-test/ftp"
docker_image_tag["mysql"]="registry.local:5000/xrender-ax-test/mysql"

# docker port to be used
declare -A docker_image_port=()
docker_image_port["portal"]="80"
docker_image_port["rabbitmq"]="5672 15672"
docker_image_port["condor"]="9618 8888"
docker_image_port["platform"]="28080"
docker_image_port["msp"]="38080"
docker_image_port["python"]="5001"
docker_image_port["redis"]="6379"
docker_image_port["ftp"]="21 2002"
docker_image_port["mysql"]="3306"

# all docker image mount this dir for execute sh after docker image run
DOCKER_SH_MOUNT=" -v $DOCKER_SH_BASE:$DOCKER_SH_BASE "

# all docker run command 
declare -A docker_image_run_command=()
docker_image_run_command["portal"]="docker run -itd --name xrender_nginx --net=host --privileged -v $DOCKER_DATA_BASE/portal:/root/nginx/portal $DOCKER_SH_MOUNT ${docker_image_tag[portal]}"
docker_image_run_command["rabbitmq"]="docker run -d --name xrender_rabbitmq --net=host --privileged  -e RABBITMQ_USERNAME=xrender -e RABBITMQ_PASSWORD=xrender $DOCKER_SH_MOUNT ${docker_image_tag[rabbitmq]}"
docker_image_run_command["condor"]="docker run -itd --name xrender_condor --net=host --privileged $DOCKER_SH_MOUNT ${docker_image_tag[condor]}"
docker_image_run_command["platform"]="docker run -itd --privileged --name xrender_platform --net=host $DOCKER_SH_MOUNT ${docker_image_tag[platform]}"
docker_image_run_command["msp"]="docker run -itd --name xrender_msp --net=host --privileged $DOCKER_SH_MOUNT ${docker_image_tag[msp]}"
docker_image_run_command["python"]="docker run -itd --net=host --privileged --name xrender_python -e LANG=C.UTF-8 $DOCKER_SH_MOUNT ${docker_image_tag[python]}"
docker_image_run_command["redis"]="docker run --name xrender_redis -d --restart=always  --net=host --privileged $DOCKER_SH_MOUNT ${docker_image_tag[redis]}"
docker_image_run_command["ftp"]="docker run -itd --net=host --privileged --name xrender_ftp -v $DOCKER_DATA_BASE/ftp:/home/ftp1 $DOCKER_SH_MOUNT ${docker_image_tag[ftp]}"
docker_image_run_command["mysql"]="docker run -itd --net=host --privileged --name xrender_mysql $DOCKER_SH_MOUNT ${docker_image_tag[mysql]}"


check_port()
{
    echo_subtitle "check_port $@"
    type=$1
    ports=${docker_image_port[$type]}
    sleep 10
    for port in $ports ; do
        result=`netstat -anp | grep ':'$port | awk '{if($6=="LISTEN") print $4}'`
        [ -z $result ] && (fail "can not find listen $port ") 
    done
    return 0
}


docker_load_image()
{
    echo_subtitle "docker_load_image $@"
    tag=$1
    image_path=${docker_image_path[$tag]}
    [ ! -f $image_path ] && (fail "$image_path not exist")
    image_tag=${docker_image_tag[$tag]}
    result=`docker images | grep "$image_tag" | awk '{print $1}'`
    [ ! -z "$result" ] && ( LOG "$tag image exist , do not load" ; return 0 )
    docker load -i $image_path
}

docker_run_image()
{
    echo_subtitle "docker_run_image $@"
    tag=$1
    run_command=${docker_image_run_command[$tag]}
    LOG $run_command
    $run_command
}

modify_docker()
{
    sleep 10
    echo_subtitle "modify_docker $@"
    ip=$1
    type=$2
    id=$(docker ps -a |grep $type|awk '{print $1}'|head -n 1)
    [ -z $id ] && (fail "can not find $type running docker")
    docker exec -it $id bash $DOCKER_SH_BASE/$type.sh $ip
}

docker_load_run()
{
    echo_title "docker_load_run $@"
    type="$1"
    docker_load_image $type
    docker_run_image $type
}

    
get_host_ip()
{
    eth=`route -n | awk '{if($1=="0.0.0.0" || $1=="default") print $8 }' | head -n 1`
    [ -z $eth ] && (fail "can not find default gatway")
    ip=`ifconfig $eth  | grep -E 'inet.[0-9]' | grep -v '127.0.0.1' | awk '{ print $2}'`
    [ -z $ip ] && ip=`ifconfig $eth | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'`
    [ -z $ip ] && (fail "can not find ip")
    echo $ip
}


install_common()
{
    host_ip=`get_host_ip`
    docker_tag=$1
    docker_load_run $docker_tag
    [ "$?" != "0" ] && ( fail "docker_load_run $docker_tag failed" )
    modify_docker $host_ip $docker_tag
    [ "$?" != "0" ] && ( fail "modify_docker $host_ip $docker_tag failed" )
    check_port $docker_tag
    [ "$?" != "0" ] && ( fail "check_port $docker_tag failed" )
}

usage()
{
    if [ "$#" != "0" -o "$#" != "1" ] ; then 
		echo "usage: $0 <IP_ADDRESS>"
		echo "   IP_ADDRESS is an option"
		exit 1
	fi
}

main()
{
	usage $*
    # check linux releas type
    check_system
    
    # install latest docker
    install_docker
    
    # unzip data file
    install_data

    # unzip sh file
    install_sh
    
    # all docker types
    all_tag="
    mysql
    redis
    ftp
    portal
    rabbitmq
    python
    condor
    platform
    msp
    "
    
    for tag in $all_tag ; do
        # install docker image & run docker image & modify all configures
        install_common $tag
    done
}

main
