# This is an alpine linux based tiny qmail server image
# It includes only smtp and send daemon that managed by supervisor.
FROM alpine:3.4

MAINTAINER Cagri Ersen <cagri.ersen@secopstech.io>

ADD ./scripts /scripts

RUN apk --no-cache add build-base openssl openssl-dev curl groff && \
    chmod +x /scripts/* && \
    /scripts/q-installer-with-daemontools.sh && \
    rm -rf /usr/src/* && \
    rm -f /package/*.tar.gz && \
    apk --no-cache del build-base curl groff && \
    rm -rf /var/cache/apk/*

# This will use daemontools to start qmail
CMD exec /command/svscanboot