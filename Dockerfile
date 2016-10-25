# This is an alpine linux based tiny qmail server image
# It includes only smtp and send daemon that managed by supervisor.
FROM debian

MAINTAINER Cagri Ersen <cagri.ersen@secopstech.io>

ADD ./scripts /scripts

RUN apk --no-cache add build-base curl groff && \
    chmod +x /scripts/* && \
    # There are two options in here, supervisor or daemontools
    # If you want to use supervisord, then set this as /scripts/q-installer-with-supervisor.sh
    # I prefer daemontools because supervisor installation increases the image size to ~50MB.
    /scripts/q-installer-with-daemontools.sh && \
    rm -rf /usr/src/* && \
    rm -f /package/*.tar.gz && \
    apk --no-cache del build-base curl groff && \
    rm -rf /var/cache/apk/*

# Uncomment this if you want to use supervisor & set the installer script as
# /scripts/q-installer-with-supervisor.sh below.

#ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

# This will use daemontools to start qmail
CMD exec /command/svscanboot