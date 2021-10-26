# TODO: Update to the real image location
FROM mcr.microsoft.com/fidalgo/core:latest
WORKDIR /

# install bicep
RUN az bicep install

# Grab all .sh files from actions.d, copy to
# root actions.d, and ake them all executable
COPY actions.d/* /actions.d/
RUN find /actions.d/ -type f -iname "*.sh" -exec chmod +x {} \;
