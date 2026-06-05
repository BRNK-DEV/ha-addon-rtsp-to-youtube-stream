ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base:latest
FROM ${BUILD_FROM}

# Install FFmpeg
RUN apk add --no-cache ffmpeg

# Copy the run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT []
CMD ["/run.sh"]
