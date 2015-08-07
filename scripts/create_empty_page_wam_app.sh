#!/bin/bash
# remove existing empty page app 
APP_PATH="/usr/palm/applications/com.palm.app.myapp"
BAREMOON_PATH="/usr/palm/applications/com.palm.app.baremoon"
rm -rf ${APP_PATH} 
mkdir ${APP_PATH} 
# suppose baremoon app exists, copy icons from there 
cp -f ${BAREMOON_PATH}/icon.png ${APP_PATH}/
echo "<html><head><title>redirect index.html</title></head><body>This is empty page test.<script> PalmSystem.stageReady(); </script><body></html>" > ${APP_PATH}/index.html
echo '{"id": "com.palm.app.myapp","version": "1.0.1","vendor": "LG","type": "web","main": "index.html","title": "MyApp","icon": "icon.png","uiRevision": "2","visible": true}' > ${APP_PATH}/appinfo.json
# reboot at the end to register app
reboot
