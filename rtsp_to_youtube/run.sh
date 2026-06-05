#!/usr/bin/with-contenv bashio

RTSP_URL=$(bashio::config 'rtsp_url')
YOUTUBE_KEY=$(bashio::config 'youtube_key')

bashio::log.info "Starting RTSP -> YouTube stream"
bashio::log.info "RTSP URL: ${RTSP_URL}"

while true; do
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

  bashio::log.warning "ffmpeg exited, restarting in 10 seconds"
  sleep 10
done
