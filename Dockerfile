FROM alpine:latest

# Install required tools
RUN apk add --no-cache bash docker-cli tar python3 py3-pip py3-virtualenv

# Create a virtual environment and install the required Python packages
RUN python3 -m venv /opt/venv \
    && . /opt/venv/bin/activate \
    && pip install google-cloud-storage

# Copy the script into the container
COPY volume_manager.sh /usr/local/bin/volume_manager.sh
RUN chmod +x /usr/local/bin/volume_manager.sh

# Set the virtual environment as the default Python environment
ENV PATH="/opt/venv/bin:$PATH"

# Entry point for the container
ENTRYPOINT ["/usr/local/bin/volume_manager.sh"]
