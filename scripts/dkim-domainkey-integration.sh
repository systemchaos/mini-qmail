#!/usr/bin/env bash

# Installation
mkdir /usr/src && cd /usr/src
apk --no-cache add curl openssl-dev libstdc++ make g++
curl http://heanet.dl.sourceforge.net/project/libdkim/libdkim/1.0.21/libdkim-1.0.21.zip -o libdkim-1.0.21.zip
curl http://patchlog.com/wp-content/uploads/2007/05/libdkim.patch -o libdkim.patch
curl http://patchlog.com/wp-content/uploads/2007/05/libdkim2.patch -o libdkim2.patch
curl http://netassist.dl.sourceforge.net/project/domainkeys/libdomainkeys/0.69/libdomainkeys-0.69.tar.gz -o libdomainkeys-0.69.tar.gz
tar xvf libdomainkeys-0.69.tar.gz
cd libdomainkeys-0.69
make
cp dktest /usr/local/bin/
chown root:root /usr/local/bin/dktest
chmod +x /usr/local/bin/dktest
unzip  libdkim-1.0.21.zip
cd libdkim
patch -p1 < ../libdkim.patch
patch -p1 < ../libdkim2.patch
cd src/
make LINUX=y
cp libdkimtest /usr/local/bin
apk --no-cache del curl openssl-dev libstdc++ make g++

# Configuration
cd /usr/src
curl https://www.syslogs.org/downloads/domainkey -o generate-domainkey.sh
