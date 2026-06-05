#!/usr/bin/with-contenv bashio

set -e

RTSP_URL=$(bashio::config 'rtsp_url' || echo "")
YOUTUBE_KEY=$(bashio::config 'youtube_key' || echo "")

# Validate configuration
if [ -z "$RTSP_URL" ]; then
  bashio::log.error "RTSP URL not configured. Please set rtsp_url in add-on configuration."
  exit 1
fi

if [ -z "$YOUTUBE_KEY" ]; then
  bashio::log.error "YouTube Stream Key not configured. Please set youtube_key in add-on configuration."
  exit 1
fi

bashio::log.info "Starting RTSP -> YouTube stream"
bashio::log.info "RTSP URL: ${RTSP_URL}"

while true; do
  bashio::log.info "Connecting to RTSP camera..."
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

  bashio::log.warning "ffmpeg exited with code $?, restarting in 10 seconds"
  sleep 10
done
