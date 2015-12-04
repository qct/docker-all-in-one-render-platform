#!/bin/sh
echo "$1 server.xrender.local" >> /etc/hosts
service nginx reload
exit 0
