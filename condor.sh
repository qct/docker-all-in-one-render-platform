#!/bin/sh
ip_from="10.22.200.18"
ip_to=$1

files="
/etc/condor_api.conf
/var/www/htcondorAPI/configure.php
/home/work/pyCreateThumbNail.py
/home/work/pymaxCMDrender.py
/home/work/maya/pymayaSceneParser.py
/home/work/maya/pymayaCMDrender.py
/home/work/pyTileAssembly.py
/home/work/nuke/pyNukeThumbNail.py
/home/work/pymayaCMDrender.py
/home/work/convert/pyConvertStream.py
/home/work/convert/pyGetMediaInfo.py
/home/work/convert/pyJoinStream.py
/home/work/pyPhotonTileAssembly.py
/home/work/pymaxSceneParser.py
/home/work/pymaxImgs2Mov.py
/home/work/pymaxCMDrender_test.py
"

for file in $files ; do 
    sed -i "s/$ip_from/$ip_to/g" $file 
    sed -i "s/localhost/127.0.0.1/g" $file
done
service apache2 restart
kill -9 $(pidof condor_api_daemon)
/usr/sbin/condor_api_daemon -d
find /etc/condor/ -type f -exec sed -i "s/$ip_from/$ip_to/g" {} \;
service condor restart
exit 0
