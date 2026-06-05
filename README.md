# RTSP to YouTube Stream Add-on

A Home Assistant add-on that streams RTSP camera feeds directly to YouTube Live using FFmpeg with automatic restart capability.

## Features

✅ Stream RTSP cameras to YouTube Live  
✅ Automatic FFmpeg restart on crash  
✅ Configurable via Home Assistant UI  
✅ Audio stream generation (generates silence if RTSP has no audio)  
✅ Multi-architecture support (ARM, ARM64, AMD64)  
✅ No external dependencies like go2rtc required  

## Installation

1. Add this repository to Home Assistant:
   - Settings → Developer Tools → Add-ons
   - Add this repository URL: `https://github.com/BRNK-DEV/ha-addon-rtsp-to-youtube-stream`

2. Install the add-on from the add-ons store

3. Configure with your RTSP URL and YouTube stream key

4. Start the add-on

## Configuration

The add-on requires two configuration parameters:

- **rtsp_url**: The RTSP URL of your camera (e.g., `rtsp://admin:password@192.168.1.64:554/Streaming/Channels/101`)
- **youtube_key**: Your YouTube Live stream key (found in YouTube Studio → Go Live → Stream Key)

### Example Configuration

```yaml
rtsp_url: rtsp://admin:PASSWORD@192.168.1.64:554/Streaming/Channels/101
youtube_key: hsd4-e8uj-wx6a-24aq-881z
```

## How It Works

1. FFmpeg connects to your RTSP camera via TCP
2. Video stream is captured and copied (no re-encoding for performance)
3. Audio stream is generated (synthetic silence) to ensure YouTube compatibility
4. Stream is sent to YouTube via RTMP protocol
5. If the connection drops, FFmpeg automatically restarts after 10 seconds

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

**Stream not starting?**
- Verify your RTSP URL is correct and accessible
- Check your YouTube stream key is valid
- Ensure you have YouTube Live enabled on your account

**Connection drops frequently?**
- Check network stability to your camera
- Verify RTSP camera credentials
- Check YouTube rate limits

**No audio in stream?**
- This is expected - the add-on generates synthetic audio if the RTSP source has none

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
