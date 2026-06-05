#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Source bashio functions
if [ -f "/usr/lib/bashio/bashio.sh" ]; then
  source /usr/lib/bashio/bashio.sh
  USE_BASHIO=true
else
  USE_BASHIO=false
fi

# Logging function
log_info() {
  echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
  echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Get config values
if [ "$USE_BASHIO" = true ]; then
  RTSP_URL=$(bashio::config 'rtsp_url' 2>/dev/null || echo "")
  YOUTUBE_KEY=$(bashio::config 'youtube_key' 2>/dev/null || echo "")
  BITRATE=$(bashio::config 'bitrate' 2>/dev/null || echo "2500k")
  RTSP_TIMEOUT=$(bashio::config 'rtsp_timeout' 2>/dev/null || echo "10")
  RECONNECT_DELAY=$(bashio::config 'reconnect_delay' 2>/dev/null || echo "10")
else
  RTSP_URL=${RTSP_URL:-""}
  YOUTUBE_KEY=${YOUTUBE_KEY:-""}
  BITRATE=${BITRATE:-"2500k"}
  RTSP_TIMEOUT=${RTSP_TIMEOUT:-"10"}
  RECONNECT_DELAY=${RECONNECT_DELAY:-"10"}
fi

# Validate configuration
if [ -z "$RTSP_URL" ]; then
  log_error "RTSP URL not configured. Please set rtsp_url in add-on configuration."
  exit 1
fi

if [ -z "$YOUTUBE_KEY" ]; then
  log_error "YouTube Stream Key not configured. Please set youtube_key in add-on configuration."
  exit 1
fi

# Additional validation
if [ -z "$BITRATE" ] || [ -z "$RTSP_TIMEOUT" ] || [ -z "$RECONNECT_DELAY" ]; then
  log_warning "Using default settings for missing configuration values"
  BITRATE=${BITRATE:-"2500k"}
  RTSP_TIMEOUT=${RTSP_TIMEOUT:-"10"}
  RECONNECT_DELAY=${RECONNECT_DELAY:-"10"}
fi

log_info "=========================================="
log_info "RTSP to YouTube Stream Starter"
log_info "=========================================="
log_info "Video Bitrate: $BITRATE"
log_info "RTSP Timeout: ${RTSP_TIMEOUT}s"
log_info "Reconnect Delay: ${RECONNECT_DELAY}s"
log_info "=========================================="

RECONNECT_ATTEMPTS=0
MAX_BACKOFF=120

while true; do
  RECONNECT_ATTEMPTS=$((RECONNECT_ATTEMPTS + 1))
  
  log_info "Connection attempt #$RECONNECT_ATTEMPTS - Connecting to RTSP camera..."
  
  # Store start time for health check
  START_TIME=$(date +%s)
  
  # Run FFmpeg with production-grade settings
  ffmpeg \
    -rtsp_transport tcp \
    -timeout $((RTSP_TIMEOUT * 1000000)) \
    -use_wallclock_as_timestamps 1 \
    -fflags +genpts \
    -i "${RTSP_URL}" \
    -f lavfi -i "anullsrc=channel_layout=stereo:sample_rate=44100" \
    -map 0:v:0 \
    -map 1:a:0 \
    -c:v libx264 \
    -b:v "${BITRATE}" \
    -preset ultrafast \
    -c:a aac \
    -b:a 128k \
    -ar 44100 \
    -ac 2 \
    -flvflags no_duration_filesize \
    -f flv \
    -maxrate 5000k \
    -bufsize 10000k \
    "rtmp://a.rtmp.youtube.com/live2/${YOUTUBE_KEY}"

  EXIT_CODE=$?
  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))

  # Health check: if connection closed after < 5 seconds, it's probably a connection error
  if [ $DURATION -lt 5 ]; then
    log_error "Stream disconnected after only ${DURATION}s - possible connection error"
    
    # Exponential backoff with max limit
    BACKOFF=$((RECONNECT_DELAY * RECONNECT_ATTEMPTS))
    if [ $BACKOFF -gt $MAX_BACKOFF ]; then
      BACKOFF=$MAX_BACKOFF
    fi
    
    log_warning "Waiting ${BACKOFF}s before reconnect... (attempt $RECONNECT_ATTEMPTS)"
    sleep "$BACKOFF"
  else
    # Normal disconnect, reset counter
    log_info "Stream ran for ${DURATION}s before disconnecting"
    RECONNECT_ATTEMPTS=0
    log_warning "Connection closed normally. Reconnecting in ${RECONNECT_DELAY}s..."
    sleep "$RECONNECT_DELAY"
  fi
done

