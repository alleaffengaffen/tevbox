#!/bin/sh
# Note: script is executed as root
echo "Hello World! I'm starting up now at $(date -R)!"

cd /tmp && git clone https://github.com/the-technat/tevbox

mkdir -p /opt/termination-handler

cp -r /tmp/tevbox/termination-handler /opt/termination-handler
