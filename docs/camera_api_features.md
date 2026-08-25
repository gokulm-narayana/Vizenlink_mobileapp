# Camera Features — Implementation Status

> **Reference Document for Feature Tracking**  
> Tracks which features are fully implemented and working across local and remote connections.

---

### Core Camera Features

| Feature | Description | LAN (Local Wi-Fi) | WAN (Remote/Cloud) |
|---|---|:---:|:---:|
| **Live Video Streaming** | View the real-time camera feed. | ✅ Working (WebRTC) | ✅ Working (KVS/HLS) |
| **Two-Way Talk (Audio)** | Speak through the camera's speaker. | ✅ Working (WebRTC) | ❌ Not Supported |
| **Snapshot Capture** | Take a still photo from the live feed. | ✅ Working (Raw JPEG) | ✅ Working (Encrypted) |
| **Night Vision** | Switch between standard IR (B&W), Color, or Smart. | ✅ Working | ✅ Working |
| **Privacy Mode** | Completely disable the camera feed for privacy. | ✅ Working | ✅ Working |
| **Privacy Zones / Masks** | Black out specific sensitive areas in the video. | ✅ Working | ✅ Working |
| **Local SD Card Recording** | Continuously record video to an SD card. | ✅ Working | ✅ Working |

---

### Alarms & Smart Events

| Feature | Description | LAN (Local Wi-Fi) | WAN (Remote/Cloud) |
|---|---|:---:|:---:|
| **Active Deterrence** | Manually trigger the Siren, Spotlight, or Warning. | ✅ Working | ✅ Working |
| **Supported Event List** | Query what AI alerts the camera supports (e.g. Person, Pet). | ✅ Working | ❌ Not Supported |
| **Event Preferences** | Choose which AI alerts to receive. | ✅ Working | ✅ Working |
| **Supported Responses** | Query which deterrence actions can be linked to events. | ✅ Working | ❌ Not Supported |
| **Event Auto-Response** | Automatically fire the Siren/Spotlight on specific events. | ✅ Working | ✅ Working |

---

### Advanced Image Settings

| Feature | Description | LAN (Local Wi-Fi) | WAN (Remote/Cloud) |
|---|---|:---:|:---:|
| **Video Quality Controls** | Adjust stream resolution, frame rate, and bitrate. | ✅ Working | ✅ Working |
| **Image Tuning (ISP)** | Adjust brightness, contrast, saturation, and sharpness. | ✅ Working | ✅ Working |
| **WDR (Wide Dynamic Range)**| Improve visibility in high-contrast lighting. | ✅ Working | ✅ Working |
| **Mirror / Flip Image** | Rotate the camera feed 180° for ceiling mounts. | ✅ Working | ✅ Working |
| **Anti-Flicker** | Match local power grid frequency (50Hz/60Hz). | ✅ Working | ✅ Working |
| **Video Overlays (OSD)** | Show a custom camera name and live timestamp. | ✅ Working | ✅ Working |

---

### Device Management

| Feature | Description | LAN (Local Wi-Fi) | WAN (Remote/Cloud) |
|---|---|:---:|:---:|
| **Device Info & Settings** | Update the camera's name, location, and timezone. | ✅ Working | ✅ Working |
| **Admin Password** | Change the camera's admin password. | ✅ Working | ✅ Working |
| **Remote Reboot** | Restart the camera without unplugging it. | ✅ Working | ✅ Working |
| **Factory Reset (Soft)** | Wipe settings but keep Wi-Fi configuration. | ✅ Working | ✅ Working |
| **Factory Reset (Hard)** | Complete wipe including Wi-Fi (requires re-onboarding). | ✅ Working | ✅ Working |
