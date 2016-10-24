#!/usr/bin/env bash

source env

# Installation
cd /usr/src
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
cd ../
unzip  libdkim-1.0.21.zip
cd libdkim
patch -p1 < ../libdkim.patch
patch -p1 < ../libdkim2.patch
cd src/
make LINUX=y
cp libdkimtest /usr/local/bin

# Configuration
cd /usr/src
curl https://www.syslogs.org/downloads/domainkey -o generate-domainkey.sh

sh generate-domainkey.sh domain.com genel

${QMAIL_HOME}/bin/qmailctl stop

mv ${QMAIL_HOME}/bin/qmail-remote ${QMAIL_HOME}/bin/qmail-remote.orig

cat > ${QMAIL_HOME}/bin/qmail-remote <<EOF
#!/bin/sh
# version 7
PATH=/bin:/usr/bin:/usr/local/bin

DOMAIN=\${2##*@}
[ "\$DKREMOTE" ] || DKREMOTE="/var/qmail/bin/qmail-remote.orig"
[ "\$SELECTOR" ] || SELECTOR=\$(cat "/etc/domainkeys/\$DOMAIN/selector")
[ "\$DKSIGN" ] || DKSIGN="/etc/domainkeys/\$DOMAIN/rsa.private_\$SELECTOR"

if [ -r "\$DKSIGN" ] ; then

        tmp=\`mktemp -t dk.sign.XXXXXXXXXXXXXXXXXXX\`
        tmp2=\`mktemp -t dk2.sign.XXXXXXXXXXXXXXXXXXX\`
        tmp3=\`mktemp -t dk3.sign.XXXXXXXXXXXXXXXXXXX\`
        tmp4=\`mktemp -t dk4.sign.XXXXXXXXXXXXXXXXXXX\`
        /bin/cat - >"\$tmp"

        /usr/local/bin/dktest -s "\$DKSIGN" -c nofws d="\$DOMAIN" -h <"\$tmp" >> "\$tmp2" 2>&1

        (/bin/cat "\$tmp2" "\$tmp" |tr -d "\\015") > "\$tmp3"

        /usr/local/bin/libdkimtest -d"\$DOMAIN" -y"\$SELECTOR" -z1 -s "\$tmp3" "\$DKSIGN" "\$tmp4" 2>/dev/null

        (/bin/cat "\$tmp4" |tr -d "\\015") | "\$DKREMOTE" "\$\@"
        retval=\$\?
                rm "\$tmp" "\$tmp2" "\$tmp3" "\$tmp4"
        exit \$\retval
else
        # No signature added
        exec "\$DKREMOTE" "\$\@"
fi
EOF

chown root:qmail ${QMAIL_HOME}/bin/qmail-remote
chmod 755 ${QMAIL_HOME}/bin/qmail-remote

apk --no-cache del curl openssl-dev libstdc++ make g++