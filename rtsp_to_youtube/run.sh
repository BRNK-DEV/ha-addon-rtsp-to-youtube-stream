#!/bin/bash

set -e

# Source bashio functions
if [ -f "/usr/lib/bashio/bashio.sh" ]; then
  source /usr/lib/bashio/bashio.sh
fi

# Get config values
if declare -f bashio::config >/dev/null 2>&1; then
  RTSP_URL=$(bashio::config 'rtsp_url' 2>/dev/null || echo "")
  YOUTUBE_KEY=$(bashio::config 'youtube_key' 2>/dev/null || echo "")
else
  # Fallback if bashio not available
  RTSP_URL=${RTSP_URL:-""}
  YOUTUBE_KEY=${YOUTUBE_KEY:-""}
fi

# Validate configuration
if [ -z "$RTSP_URL" ]; then
  echo "ERROR: RTSP URL not configured. Please set rtsp_url in add-on configuration."
  exit 1
fi

if [ -z "$YOUTUBE_KEY" ]; then
  echo "ERROR: YouTube Stream Key not configured. Please set youtube_key in add-on configuration."
  exit 1
fi

echo "Starting RTSP -> YouTube stream"
echo "RTSP URL: ${RTSP_URL}"

while true; do
  echo "Connecting to RTSP camera..."
  ffmpeg \
    -rtsp_transport tcp \
    -use_wallclock_as_timestamps 1 \
    -fflags +genpts \
    -i "${RTSP_URL}" \
    -f lavfi -i "anullsrc=channel_layout=stereo:sample_rate=44100" \
    -map 0:v:0 \
    -map 1:a:0 \
    -c:v copy \
    -c:a aac \
    -b:a 128k \
    -ar 44100 \
    -ac 2 \
    -f flv \
    "rtmp://a.rtmp.youtube.com/live2/${YOUTUBE_KEY}"

  EXIT_CODE=$?
  echo "FFmpeg exited with code ${EXIT_CODE}, restarting in 10 seconds"
  sleep 10
done
