#!/bin/sh
set curdir=`pwd`
cd `dirname $0`/../feeder
node fill-server-geoip.node.js
node feeder.node.js -e
cd "$curdir"
