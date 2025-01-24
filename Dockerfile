FROM alpine:latest

# Install required tools
RUN apk add --no-cache bash docker-cli tar python3 py3-pip py3-virtualenv
# Install Google Cloud SDK
RUN apk add --no-cache curl
RUN curl -sSL https://sdk.cloud.google.com | bash
ENV PATH $PATH:/root/google-cloud-sdk/bin



# Copy the script into the container
COPY volume_manager.sh /usr/local/bin/volume_manager.sh
RUN chmod +x /usr/local/bin/volume_manager.sh

# Set the virtual environment as the default Python environment
ENV PATH="/opt/venv/bin:$PATH"

# Entry point for the container
ENTRYPOINT ["/usr/local/bin/volume_manager.sh"]
