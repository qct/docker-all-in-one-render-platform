### [Docker](https://www.docker.com/) all in one environment of render platform

## Introduction
首先介绍一下**分布式渲染** ，核心有一下几点：
* 并行渲染，调度系统会分发job到每个可用的节点机，每个job就是一帧，同一个节点机同一时间只执行一个job。这里的可以不但指节点确实存在，还指他被加进了当前渲染所用的节点池。
* 文件去重，上传过的文件不会被再次上传，当你提交一个任务，上传文件之前会进行去重处理，在服务器上已经存在的文件不会再次上传。
* 自动回传&手动下载，渲染完毕之后会自动回传到本地（前提是你有我们的客户端^_^）或者也可以通过手动下载渲染结果。
#### 这里有什么
这是一个基于分布式渲染生产环境的all-in-one环境，把所有的组件都做成了docker容器，使得部署变得非常容易，原来部署一套环境需要2个人工作几天才能调通，现在只需要一条命令就可以实现。
#### 适用于谁
* 适用于小型的渲染农场或者工作室，他们可以通过自己内部的机器搭建小型的云渲染环境。
* 适用于喜欢折腾的Geek，当然，Geek什么都可以玩，包括这个。

## Environment
* 一台配置比较高的机器，linux系统，最好是[CentOS 7](https://www.centos.org/download/)，我们搭建生产环境用的是 10台左右的 物理机+虚拟机，所以机器配置最好比较高。
* 一台一般的windows机器，系统我们生产用的是Windows 2012。别的版本其实我觉得都还OK。

## Pre-install
环境搭建之前，需要先下载我已经做好的docker image，这个比较大，一共有9个组件，压缩之后3.57G，我已经传到网盘上了。这里面都是docker save出来的image。  

网盘链接: [http://pan.baidu.com/s/1ntF69M5](http://pan.baidu.com/s/1ntF69M5) 密码: q5nm

## Server Install
镜像下载完之后在linux机器上解压，里面也包括了这些shell，进入主目录执行执行下面命令，会把这9大组件通过docker方式都安装并启动容器。
```bash
docker rm -f $(docker ps -a|awk '{print $1}'|grep -v 'CONTAINER') ; sh -x install_xrender_all.sh `pwd`
```
## Render Node Install 
未完待续。。。
## About

我们是2个人的团队，docker以及系统调试是我弄的，安装shell是@Jorge Jiang写的。
