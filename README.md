Overview
========

This is an alpine 3.4 based minimal qmail server (only 9.728 MB)
It only contains qmail-send and qmail-smtp services that run by daemontools.

Default installation includes big-dns and qmail-channel patches as well as domainkey and dkim support,
and qmail configured for three major email vendors (Gmail, Yahoo and MS) to throttle outbound delivery which 
qmail will open 10 concurrent connections to these three vendors and for all the other outbound delivery concurrent 
connection limit is 50 by default. To change the throttle settings, see "Throttle Settings" section below.

How to
======

To create a container from this image, simple run:

```
docker run -d --name CONTAINER_NAME -t secopstech/mini-qmail
```

****Customizations****

You need to customize qmail installations for your environment. 
For example you may want to change hostname and grant relay access to spesific IPs.

***Change Hostname***

In the base image, qmail's servername is mx01.domain.local by default which you want to change it with your FQDN.
To do this, just trigger qmail-configurator with your FQDN like below:


```
docker exec -i CONTAINER_NAME /scripts/qmail-configurator mx.foo.bar
```

This will configure the hostname as spesified FQDN and restart the services.

***Relay Client***

To grant relay access to a spesific IP or IP range, you can trigger qmail-configurator with relayclient paramater:

```
# Granting access to an IP address
docker exec -i CONTAINER_NAME /scripts/qmail-configurator 1.1.1.1

# Or for all /24 IP range
docker exec -i CONTAINER_NAME /scripts/qmail-configurator 2.2.2.

```

With this setup, qmail will accept outbound email requests from 1.1.1.1 and 2.2.2.0/24


DKIM/Domainkey Support
======================

When you run a container from this image, it will setup a default DKIM keypair to sign every outgoing emails.
To grab the pubkey information which will be needed to create a TXT record for your sender domain(s)
check the /tmp/DKIM_TXT_RECORD_INFO.txt file:

```
docker exec -i CONTAINER_NAME cat /tmp/DKIM_TXT_RECORD_INFO.txt
```