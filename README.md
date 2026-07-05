# RTSP to YouTube Stream Add-on

A Home Assistant add-on that streams RTSP camera feeds directly to YouTube Live using FFmpeg with automatic restart capability.

## Features

✅ Stream RTSP cameras to YouTube Live  
✅ **Automatic FFmpeg restart on crash**  
✅ **Health monitoring** – detects failed connections  
✅ **Exponential backoff** – prevents connection storms  
✅ **Configurable bitrate** – adapt to your network  
✅ **Timeout settings** – reliable RTSP connections  
✅ **Synthetic audio** – generates audio if camera has none  
✅ **Multi-architecture support** (ARM, ARM64, AMD64)  
✅ **No external dependencies** like go2rtc required  
✅ **Color-coded logging** – easy to read diagnostics  

## Installation

1. Add this repository to Home Assistant:
   - Settings → Developer Tools → Add-ons
   - Add this repository URL: `https://github.com/BRNK-DEV/ha-addon-rtsp-to-youtube-stream`

2. Install the add-on from the add-ons store

3. Configure with your RTSP URL and YouTube stream key

4. Start the add-on

## Configuration

### Required Parameters

- **rtsp_url**: The RTSP URL of your camera (e.g., `rtsp://admin:password@192.168.1.64:554/Streaming/Channels/101`)
- **youtube_key**: Your YouTube Live stream key (found in YouTube Studio → Go Live → Stream Key)

### Optional Parameters (v2.1.0+)

- **bitrate**: Video encoding bitrate (default: `2500k`)
  - Examples: `1500k` (low), `2500k` (medium), `5000k` (high)
  - Adjust based on your network and camera resolution
  
- **rtsp_timeout**: RTSP connection timeout in seconds (default: `15`, range: 5-120)
  - Kept low by default so a stalled/frozen camera connection is detected quickly and retried, rather than blocking for minutes before the reconnect loop even starts. Increase if your camera is slow to respond and you see false-positive reconnects.
  
- **reconnect_delay**: Delay before reconnecting after disconnect (default: `5`, range: 5-300)
  - With health monitoring: auto-increases up to 2 minutes on repeated failures

### Example Configuration

```yaml
rtsp_url: rtsp://admin:PASSWORD@192.168.1.64:554/Streaming/Channels/101
youtube_key: hsd4-e8uj-wx6a-24aq-881z
bitrate: 2500k
rtsp_timeout: 15
reconnect_delay: 5
```

## How It Works

1. **Connection Phase**
   - Connects to RTSP camera via TCP with configurable timeout
   - Sets RTSP and FFmpeg parameters for reliable streaming

2. **Encoding Phase**
   - Video stream: H.264 encoding with configurable bitrate
   - Audio stream: AAC encoding at 128k bitrate (synthetic if camera has none)
   - Combines both streams into FLV format for YouTube

3. **Streaming**
   - Sends stream to YouTube via RTMP protocol
   - Monitors connection health in real-time

4. **Reconnection Logic**
   - **Normal disconnect**: Waits `reconnect_delay` seconds, then reconnects
   - **Quick disconnect** (< 5 seconds): Uses exponential backoff
   - **Max backoff**: 2 minutes to prevent connection storms
   - **Auto-recovery**: Attempts reconnect indefinitely with health monitoring

## About Interruptions and YouTube Broadcasts

This add-on retries the RTSP→YouTube connection indefinitely, but YouTube itself will end a live broadcast after enough time passes without incoming data — that timeout is undocumented and not configurable, so no add-on setting can guarantee a specific grace period (e.g. 10 minutes). The `rtsp_timeout`/`reconnect_delay` defaults above are kept low specifically to reconnect as fast as possible and maximize the chance a brief interruption resolves before YouTube ends the broadcast.

For interruptions that do end the broadcast (including after a nightly reboot), enable **auto-start** and **auto-stop** on a persistent/reusable stream key in YouTube Studio (Go Live → Stream → Advanced settings). With that enabled, YouTube automatically starts a new broadcast as soon as this add-on reconnects — no manual restart needed. Note this does mean a new interruption produces a separate broadcast/video rather than one continuous recording.

## Supported Architectures

- `aarch64` (ARM 64-bit)
- `amd64` (Intel/AMD 64-bit)
- `armv7` (ARM 32-bit)

## Requirements

- Home Assistant instance running
- RTSP camera on the network
- YouTube Live stream key (from your YouTube account)
- Network access to `rtmp://a.rtmp.youtube.com`

## Troubleshooting

**Diagnosing a past interruption?**
- The add-on's Log tab (and the container's own stdout) only goes back to the last time the container was created — a reboot, update, or manual restart wipes it, which makes diagnosing overnight interruptions hard.
- The script also mirrors everything to `/data/rtsp_to_youtube.log`, which HA persists across container restarts/recreates. Read it via the SSH/Terminal add-on with `docker exec addon_<hash>_rtsp_to_youtube cat /data/rtsp_to_youtube.log` (find the exact container name with `docker ps`).

**Stream not starting?**
- Verify your RTSP URL is correct and accessible
- Check your YouTube stream key is valid
- Ensure you have YouTube Live enabled on your account

**"Connection attempt #N" repeats in logs?**
- Indicates RTSP connection failure – check camera URL and credentials
- Try increasing `rtsp_timeout` if camera is slow
- Check camera is accessible on your network

**Frequent disconnects / bitrate drops?**
- Reduce `bitrate` setting if network is unstable
- Check network stability between Home Assistant and camera
- Verify YouTube rate limits aren't reached

**Connection timeout errors?**
- Increase `rtsp_timeout` (e.g., 20, 30 seconds)
- Some cameras need longer handshake time

**High CPU usage?**
- Reduce `bitrate` for lower encoding complexity
- Check if camera feed is high resolution (lower is better)

**No audio in stream?**
- Expected behavior if RTSP source has no audio
- Add-on generates synthetic audio automatically

**Exponential backoff warnings?**
- Normal during network issues – prevents connection storms
- Check camera/network health when these appear frequently

## Development

To rebuild the add-on locally:

```bash
docker build -t ha-addon-rtsp-to-youtube .
```

## License

This project is licensed under the MIT License.

## Support

For issues, feature requests, or questions, please open an issue on the GitHub repository.

---

**Repository**: https://github.com/BRNK-DEV/ha-addon-rtsp-to-youtube-stream  
**Maintainer**: BRNK-DEV
