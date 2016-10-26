#!/bin/sh

set -e

source /scripts/env

# Installation
cd /usr/src
curl ${LIBDKIM_DL_URL} -o libdkim-1.0.19-patched.tgz
curl ${LIBDOMAINKEY_DL_URL} -o libdomainkeys-0.69.tar.gz
tar xvf libdomainkeys-0.69.tar.gz
cd libdomainkeys-0.69
make
cp dktest /usr/local/bin/
cp libdomainkeys.a /usr/local/lib
cp domainkeys.h dktrace.h  /usr/include/
chown root:root /usr/local/bin/dktest
chmod +x /usr/local/bin/dktest
cd ../
tar xfz libdkim-1.0.19-patched.tgz
cd libdkim-1.0.19-patched/src
make LINUX=y
cp libdkimtest /usr/local/bin
chmod +x /usr/local/bin/libdkimtest

# Configuration
cd /usr/src
curl ${DOMAINKEY_GENERATOR} -o generate-domainkey.sh

# This will create a keypair for "default.domain" with a selector named "genel"
# and the qmail sign every email with this key and selector
# so you need to create a TXT record as explained in /tmp/DKIM_TXT_RECORD_INFO.txt
# for your domain.
sh generate-domainkey.sh default.domain genel > /tmp/DKIM_TXT_RECORD_INFO.txt
sed -i -e 's#genel._domainkey.default.domain#genel._domainkey.YOURDOMAIN.TLD#' \
/tmp/DKIM_TXT_RECORD_INFO.txt

${QMAIL_HOME}/bin/qmailctl stop
mv ${QMAIL_HOME}/bin/qmail-remote ${QMAIL_HOME}/bin/qmail-remote.orig
cp /scripts/qmail-remote-wrapper.sh ${QMAIL_HOME}/bin/qmail-remote
chown root:qmail ${QMAIL_HOME}/bin/qmail-remote
chmod 755 ${QMAIL_HOME}/bin/qmail-remote
${QMAIL_HOME}/bin/qmailctl start
cd ~