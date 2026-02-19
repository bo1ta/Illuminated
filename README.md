# Illuminated

A macOS music player written in Objective-C, with real-time projectM visualizers inspired by the old Winamp days

[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)]()
[![License](https://img.shields.io/badge/license-MIT-blue)]()

### Features

- Plays common audio formats: MP3, M4A/AAC, WAV, FLAC, OGG, Opus, AIFF and more
- Real-time audio-reactive visualizers powered by [projectM](https://github.com/projectM-visualizer/projectm) with 600 presets included
- Playlist management with drag-and-drop support
- Sidebar with All Music, Playlists, and Albums sections
- File Browser for easy navigation
- Metadata reading via [TagLib](https://taglib.org) (artist, album, cover art, etc.)
- BPM analysis ported from [bpm-tools](https://www.pogo.org.uk/~mark/bpm-tools/)
  
---

### Preview
<img width="803" height="480" alt="Screenshot 2026-02-08 at 21 14 16" src="https://github.com/user-attachments/assets/c0618a6d-2695-4d4b-8a0c-3e5729ba9b66" />
<img width="803" height="480" alt="Screenshot 2026-02-08 at 21 25 48" src="https://github.com/user-attachments/assets/b7ed37b3-c200-40dd-ae88-bc82872c98e3" />
<img width="803" height="480" alt="Screenshot 2026-02-08 at 21 25 59" src="https://github.com/user-attachments/assets/5a1e646c-7929-4c66-90d3-d92b2a898422" />

---

### Installation

1. Download the latest version
2. Unzip the file
3. Drag `Illuminated.app` to your **Applications** folder

### Usage

- Drag audio files or folders onto the app window to add to library
- Double-click tracks or use the sidebar to play
- Right-click tracks → Add to Playlist / Enqueue
- Switch visualizers via the controls in the visualization view

### Building from Source

```bash
git clone https://github.com/bo1ta/Illuminated.git
cd Illuminated
open Illuminated.xcodeproj
```

Build & Run

### LICENSE

Illuminated is available under the MIT license. See LICENSE for details
