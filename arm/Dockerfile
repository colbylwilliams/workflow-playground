# TODO: Update to the real image location
FROM mcr.microsoft.com/fidalgo/core:latest
WORKDIR /

# install bicep
RUN az bicep install

# Grab all .sh files from docker-runner.d, copy to
# root docker-runner.d, and ake them all executable
COPY docker-runner.d/* /docker-runner.d/
RUN find /docker-runner.d/ -type f -iname "*.sh" -exec chmod +x {} \;
