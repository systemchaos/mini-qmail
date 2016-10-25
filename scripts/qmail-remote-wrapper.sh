#!/usr/bin/env sh
PATH=/bin:/usr/bin:/usr/local/bin

#
# DKIM signing for qmail
#
# permissions must be 0755
#
# Author: Joerg Backschues
#

[ "$DKSIGN" ]   || DKSIGN="/etc/domainkeys/%/default"
[ "$DKREMOTE" ] || DKREMOTE="/var/qmail/bin/qmail-remote.orig"
DKREMOTE="/var/qmail/bin/qmail-remote.orig"

# parent domains (see RFC 4871 3.8)

FQDN=${2##*@}
TLD=`/bin/echo $FQDN | /usr/bin/awk 'BEGIN {FS = "."} {print $NF}'`
DOM=`/bin/echo $FQDN | /usr//bin/awk 'BEGIN {FS = "."} {print $(NF-1)}'`

# get domainkey file

if echo $DKSIGN |grep -q "%" ; then
    DOMAIN=$DOM.$TLD
    DKSIGN="${DKSIGN%%%*}${DOMAIN}${DKSIGN#*%}"
    SELECTOR=`/bin/cat /etc/domainkeys/$DOMAIN/selector`
    DKREMOTE="/var/qmail/bin/qmail-remote.orig"
fi

if [ -f "$DKSIGN" ] ; then

    # domain with domainkey

    inmsg=`/bin/mktemp -p /tmp -t dkin.XXXXXXXXXXXXXXX`
    midmsg1=`/bin/mktemp -p /tmp -t dkmid1.XXXXXXXXXXXXXXX`
    midmsg2=`/bin/mktemp -p /tmp -t dkmid2.XXXXXXXXXXXXXXX`
    outmsg=`/bin/mktemp -p /tmp -t dkout.XXXXXXXXXXXXXXX`

    # fill inmsgfile
    cat - >"$inmsg"

    # sign mesaage with domainkeys
    /usr/local/bin/dktest -s "$DKSIGN" -c nofws <"$inmsg" >> "$midmsg1" 2>&1

    # set d= as $DOMAIN
    /bin/sed -i -e 's#; d=.*;#; d='"$DOMAIN"';#g' "$midmsg1"
    /bin/sed -i -e 's#s=default ;#s='"$DOMAIN"' ;#g' "$midmsg1"

    # remove shift in
    (/bin/cat "$midmsg1" "$inmsg" | /usr/bin/tr -d '\r') > "$midmsg2"

    # sign mesaage with DKIM
    /usr/local/bin/libdkimtest -d"$DOMAIN" -y"$SELECTOR" -lt -b2 -z1 -s "$midmsg2" "$DKSIGN" "$outmsg" 2>&1

    # remove shift in and give qmail-remote
    (/bin/cat "$outmsg" | /usr/bin/tr -d '\r') | "$DKREMOTE" "$@"

    retval=$?

    #Delete tmp files
    /bin/rm -f "$inmsg" "$midmsg1" "$midmsg1" "$outmsg"

    exit $retval

else

    # domain without domainkey
    exec "$DKREMOTE" "$@"

fi