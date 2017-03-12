Overview
========

 This is an alpine 3.4 based minimal qmail server (only 9~ MB) that only contains 
qmail-send and qmail-smtp services which is usefull for transactional emails 
like welcome messages, password resets etc.

 big-dns and qmail-channel patches are already applied and domainkey/dkim support
is enabled by default for all outbound emails. For dkim/domainkey support details 
see the DKIM/Domainkey Support section.

 Also there is a default configuration to throttle outbound delivery to 3 major email
service providers. (Gmail, Yahoo and MS). With default settings qmail will open 10 
concurrent connections per provider and 50 for all the other domains. Controlling the 
pace of the outbound emails to big vendors is important thing because fast delivery
leads to ban issues especially new installed SMTP servers with a fresh IP. 
So you can set the throttle values as small as possible at first to avoid blacklisting 
and then increase them slowly week by week to gain good reputation. To change the
throttling settings see the related section below.

How To
======

To create a container from this image simply run:

```
docker run -d -t -p 25:25 \
 --name CONTAINER_NAME \
 --env="QMAIL_HOSTNAME=host.domain.ltd" \
 --env="RELAYIP=172.0.0." \
 secopstech/mini-qmail
```

Note that if you don't pass QMAIL_HOSTNAME and RELAYIP parameters mx.domain.local will be used
as qmail hostname and only 127.0.0.1 will be granted for relay.


Customizations
--------------

To customize qmail configuration later, you can use qmail-configurator. 
For example you may want to change hostname and grant relay access to your sender IPs.

**Change Hostname**

To change the hostname FQDN. To do this, just trigger qmail-configurator with your 
FQDN like below:

```
docker exec -i CONTAINER_NAME qmail-configurator set-fqdn mx.foo.bar
```

This will configure the hostname as spesified value and restart the services.
Valid values for "set-fqdn" option is: hostname - domain - FQDN. Note that, 
using a valid FQDN (with proper DNS A and PTR records) is a better choise.

**Relay Client**

To grant relay access for an IP or IP range, you can trigger qmail-configurator
with relay paramater:

```
# Grant access to an IP address or a subnet.
docker exec -i CONTAINER_NAME qmail-configurator add-relay 1.2.3.4
docker exec -i CONTAINER_NAME qmail-configurator add-relay 1.2.3.

# Or you can remove relay for an IP or a subnet.
docker exec -i CONTAINER_NAME qmail-configurator del-relay 1.2.3.4
docker exec -i CONTAINER_NAME qmail-configurator del-relay 1.2.3.

# To show the relayclients:
docker exec -i CONTAINER_NAME qmail-configurator show-relay

```

With this setup, qmail will accept outbound email requests from 1.1.1.1 and 2.2.2.0/24

**Throttle Settings**

By default outbound emails to google, yahoo and microsoft domains is limited to 10 for 
each domain. 

To change these values you can use throttle parameter like:

```
# Set concurrent limit to 30 for Yoogle domains (google.com, gmail.com)
docker exec -i CONTAINER_NAME qmail-configurator throttle google 30

# Set concurrent limit to 25 for Yahoo domains (yahoo.com, yahoo.co.uk etc.)
docker exec -i CONTAINER_NAME qmail-configurator throttle yahoo 20

# Set concurrent limit to 20 for Microsoft domains (hotmail, live, outlook etc.)
docker exec -i CONTAINER_NAME qmail-configurator throttle microsoft 20
```

throttle parameter only takes google|yahoo|microsoft values as domain and concurrent limit
number should be between 1 and 100.


DKIM/Domainkey Support
======================

When you run a container from this image, it will setup a default DKIM keypair to sign every
outgoing emails. To grab the pubkey information which will be needed to create a TXT record 
for your sender domain(s) check the /tmp/DKIM_TXT_RECORD_INFO.txt file:

```
docker exec -i CONTAINER_NAME cat /tmp/DKIM_TXT_RECORD_INFO.txt
```

