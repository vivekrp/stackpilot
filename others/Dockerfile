# Use the official Ubuntu base image
FROM ubuntu:mantic

# Set the working directory to /app
WORKDIR /app

# Copy the install script and run it
COPY install.sh .
RUN chmod +x install.sh && ./install.sh

# Copy the setup script into the working directory
COPY setup.sh .

# Make the setup script executable
RUN chmod +x setup.sh

# Set environment variables for Doppler project and config
ENV DOPPLER_PROJECT=aiplus
ENV DOPPLER_CONFIG=prd

# Use /bin/sh as the entry point to keep the container running
ENTRYPOINT ["/bin/bash"]