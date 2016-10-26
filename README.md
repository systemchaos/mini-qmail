Overview
========

This is an alpine 3.4 based minimal qmail server (only 9.728 MB) for transactional emails.
It only contains qmail-send and qmail-smtp services that run by daemontools.

qmail installation includes big-dns and qmail-channel patches as well as domainkey and dkim signing support.


How to
======

To create a container from this image, simple run:

```
docker run -d --name CONTAINER_NAME -t secopstech/mini-qmail
```

Customizations
==============

In the base image, qmail's servername is mx01.domain.local which you want to change it with your FQDN.
To do this, just trigger qmail-configurator with your parameters like below:

```
docker exec -i CONTAINER_NAME /scripts/qmail-configurator my.domain.com
```

This will configure the hostname as spesified FQDN and restart the services.

DKIM/Domainkey Support
======================

When you run a container from this image, it will setup a default DKIM keypair to sign every outgoing emails.
To grab the pubkey information which will be needed to create a TXT record for your sender domain(s)
check the /tmp/DKIM_TXT_RECORD_INFO.txt file:

```
docker exec -i CONTAINER_NAME cat /tmp/DKIM_TXT_RECORD_INFO.txt
```