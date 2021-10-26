# TODO: Update to the real image location
FROM mcr.microsoft.com/azure-cli:latest
WORKDIR /

COPY entrypoint.d/* /entrypoint.d/
COPY entrypoint.sh /entrypoint.sh
COPY actions.d/* /actions.d/

RUN chmod +x /entrypoint.sh \
    && mkdir -p /entrypoint.d && find /entrypoint.d/ -type f -iname "*.sh" -exec chmod +x {} \; \
    && mkdir -p /actions.d && find /actions.d/ -type f -iname "*.sh" -exec chmod +x {} \;

# Terminate container on stop
STOPSIGNAL SIGTERM

CMD [ "" ]
ENTRYPOINT [ "/entrypoint.sh" ]