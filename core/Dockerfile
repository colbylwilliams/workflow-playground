# TODO: Update to the real image location
FROM mcr.microsoft.com/azure-cli:latest
WORKDIR /

# Reset entrypoint and extension script
RUN rm /docker-entrypoint.sh \
    && rm /docker-entrypoint.d/*

COPY docker-entrypoint.d/* /docker-entrypoint.d/
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY docker-runner.d/* /docker-runner.d/

RUN chmod +x /docker-entrypoint.sh \
    && mkdir -p /docker-entrypoint.d && find /docker-entrypoint.d/ -type f -iname "*.sh" -exec chmod +x {} \; \
    && mkdir -p /docker-runner.d && find /docker-runner.d/ -type f -iname "*.sh" -exec chmod +x {} \;

# Terminate container on stop
STOPSIGNAL SIGTERM

CMD [ "" ]
ENTRYPOINT [ "/docker-entrypoint.sh" ]