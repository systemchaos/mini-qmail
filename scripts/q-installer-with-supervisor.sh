#!/usr/bin/env sh

set -e

QMAIL_HOME="/var/qmail"
QMAIL_LOG_DIR="/var/log/qmail"
QMAIL_DL_URL="http://www.qmail.org/netqmail-1.06.tar.gz"
QMAIL_UCSPI_URL="http://cr.yp.to/ucspi-tcp/ucspi-tcp-0.88.tar.gz"

## QMAIL INSTALL BASED ON LWQ ##
mkdir /usr/src /var/qmail && cd /usr/src
curl $QMAIL_DL_URL -o netqmail-1.06.tar.gz
tar zxf netqmail-1.06.tar.gz
cd netqmail-1.06

adduser qmaild -g nofiles -h ${QMAIL_HOME} -s /sbin/nologin -D
adduser alias -g nofiles -h ${QMAIL_HOME}/alias -s /sbin/nologin -D
adduser qmaill -g nofiles -h ${QMAIL_HOME} -s /sbin/nologin -D
adduser qmailp -g nofiles -h ${QMAIL_HOME} -s /sbin/nologin -D
addgroup qmail
adduser qmailq -g qmail -h ${QMAIL_HOME} -s /sbin/nologin -D
adduser qmailr -g qmail -h ${QMAIL_HOME} -s /sbin/nologin -D
adduser qmails -g qmail -h ${QMAIL_HOME} -s /sbin/nologin -D

make setup check
cd ../

curl $QMAIL_UCSPI_URL -o ucspi-tcp-0.88.tar.gz
tar zxf ucspi-tcp-0.88.tar.gz
cd ucspi-tcp-0.88/
patch < /usr/src/netqmail-1.06/other-patches/ucspi-tcp-0.88.errno.patch
make && make setup check

mkdir -p ${QMAIL_HOME}/supervise/qmail-send
mkdir -p ${QMAIL_HOME}/supervise/qmail-smtpd

 echo "mx01.domain.local" > /var/qmail/control/me
 echo "mx01.domain.local" > /var/qmail/control/locals
 echo "mx01.domain.local" > /var/qmail/control/rcpthosts
 echo "./Maildir" > /var/qmail/control/defaultdelivery
 echo "100" > /var/qmail/control/concurrencyincoming

cat > ${QMAIL_HOME}/supervise/qmail-send/run <<EOF
#!/bin/sh
exec ${QMAIL_HOME}/rc
EOF

chmod 755 ${QMAIL_HOME}/supervise/qmail-send/run

cat > ${QMAIL_HOME}/rc <<EOF
#!/bin/sh

# Using stdout for logging
# Using control/defaultdelivery from qmail-local to deliver messages by default

exec env - PATH="${QMAIL_HOME}/bin:\$PATH" \
qmail-start "\`cat ${QMAIL_HOME}/control/defaultdelivery\`"
EOF

chmod 755 ${QMAIL_HOME}/rc

cat > ${QMAIL_HOME}/supervise/qmail-smtpd/run <<EOF
#!/bin/sh

QMAILDUID=\`id -u qmaild\`
NOFILESGID=\`id -g qmaild\`
MAXSMTPD=\`cat ${QMAIL_HOME}/control/concurrencyincoming\`
LOCAL=\`head -1 ${QMAIL_HOME}/control/me\`

if [ -z "\$QMAILDUID" -o -z "\$NOFILESGID" -o -z "\$MAXSMTPD" -o -z "\$LOCAL" ]; then
    echo QMAILDUID, NOFILESGID, MAXSMTPD, or LOCAL is unset in
    echo ${QMAIL_HOME}/supervise/qmail-smtpd/run
    exit 1
fi

if [ ! -f ${QMAIL_HOME}/control/rcpthosts ]; then
    echo "No ${QMAIL_HOME}/control/rcpthosts!"
    echo "Refusing to start SMTP listener because it'll create an open relay"
    exit 1
fi
exec /usr/local/bin/tcpserver -v -R -l "\$LOCAL" -x /etc/tcp.smtp.cdb -c "\$MAXSMTPD" -u "\$QMAILDUID" -g "\$NOFILESGID" 0 smtp ${QMAIL_HOME}/bin/qmail-smtpd 2>&1
EOF

chmod 755 ${QMAIL_HOME}/supervise/qmail-smtpd/run

# configure supervisord to start qmail
mkdir /etc/supervisor.d/

cat > /etc/supervisord.conf <<EOF
[supervisord]
nodaemon=true
logfile=/var/log/supervisord.log

[unix_http_server]
file=/tmp/supervisor.sock

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///tmp/supervisor.sock         ; use a unix:// URL  for a unix socket

[include]
files = /etc/supervisor.d/*.conf
EOF

cat > /etc/supervisor.d/qmail-send.conf <<EOF
[program:qmail-send]
directory=${QMAIL_HOME}
environment=HOME=${QMAIL_HOME}
command=${QMAIL_HOME}/supervise/qmail-send/run
user=root
autostart=true
autorestart=true
stdout_logfile=${QMAIL_LOG_DIR}/%(program_name)s.log
stderr_logfile=${QMAIL_LOG_DIR}/%(program_name)s.log
EOF

cat > /etc/supervisor.d/qmail-smtpd.conf <<EOF
[program:qmail-smtpd]
directory=${QMAIL_HOME}
environment=HOME=${QMAIL_HOME}
command=${QMAIL_HOME}/supervise/qmail-smtpd/run
user=root
autostart=true
autorestart=true
stdout_logfile=${QMAIL_LOG_DIR}/%(program_name)s.log
stderr_logfile=${QMAIL_LOG_DIR}/%(program_name)s.log
EOF

cat > /etc/tcp.smtp <<EOF
127.:allow,RELAYCLIENT=""
172.17.:allow,RELAYCLIENT=""
EOF
tcprules /etc/tcp.smtp.cdb /etc/tcp.smtp.tmp < /etc/tcp.smtp
chmod 644 /etc/tcp.smtp.cdb

mkdir ${QMAIL_LOG_DIR}