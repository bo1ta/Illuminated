# Illuminated

A macOS music player written in Objective-C, with real-time Metal visualizers inspired by the old Winamp days

[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)]()
[![License](https://img.shields.io/badge/license-MIT-blue)]()

### Features

- Clean, native macOS interface that respects system light/dark mode
- Plays common audio formats: MP3, M4A/AAC, WAV, FLAC, OGG, Opus, AIFF and more
- Real-time audio-reactive visualizers (5+ presets) built with Metal shaders
- Playlist management with drag-and-drop support
- Sidebar with All Music, Playlists, and Albums sections
- Metadata reading via [TagLib](https://taglib.org) (artist, album, cover art, etc.)
- BPM analysis ported from [bpm-tools](https://www.pogo.org.uk/~mark/bpm-tools/) for better beat-sync potential
  
---

### Preview
<img width="803" height="480" alt="Screenshot 2026-02-08 at 21 14 16" src="https://github.com/user-attachments/assets/c0618a6d-2695-4d4b-8a0c-3e5729ba9b66" />
<img width="803" height="480" alt="Screenshot 2026-02-08 at 21 25 48" src="https://github.com/user-attachments/assets/b7ed37b3-c200-40dd-ae88-bc82872c98e3" />
<img width="803" height="480" alt="Screenshot 2026-02-08 at 21 25 59" src="https://github.com/user-attachments/assets/5a1e646c-7929-4c66-90d3-d92b2a898422" />

---

### Visualizer Presets

- **Alien Core**: 3D "raymarched" scene with organic forms for dark electronic music
- **Cosmic Void**: Cosmic patterns spawning from a tunnel
- **Space Centipede**: A giant centipede floating in the outer space
- **Circular Wave**: Radial audio visualization with color modulation
- **Triangle Fractal**: Geometric pattern generator
- **Neural Pulse**: Hyperspace/tunnel effect
- **Sine Voronoi**: Glowing and animating sine waves

*More presets can be easily added by implementing the [VisualizationPreset](https://github.com/bo1ta/Illuminated/blob/main/Illuminated/VisualizationPreset/VisualizationPreset.h) protocol*


### Installation

1. Download the latest version
2. Unzip the file
3. Drag `Illuminated.app` to your **Applications** folder

### Usage

- Drag audio files or folders onto the app window to add to library
- Double-click tracks or use the sidebar to play
- Right-click tracks → Add to Playlist / Enqueue
- Switch visualizers via the controls in the visualization view

### Why Objective-C?

The project started as a mix of curiosity and a naive "what if?" question

I'm a Swift/iOS developer by day, but I kept wondering: what did macOS app development feel like before Swift? How did people build things in the Cocoa/Objective-C era? I love music, I collect music, so an audio player felt like a natural thing to test the waters

The original plan was to embed [projectM](https://github.com/projectM-visualizer/projectm) for the classic Winamp-style visualizers. And well, it turns out that integrating it properly on Apple Sillicon is a nightmare. OpenGL is deprecated, buggy and frankly a cumbersome developer experience. So I switched to Metal for the visualizers, and the shaders are mostly vibe-coded experiments, very far from production-grade art. But they look decent and react to music nicely, so for now they work fine.

### Building from Source

```bash
git clone https://github.com/bo1ta/Illuminated.git
cd Illuminated
open Illuminated.xcodeproj
```

Build & Run

### LICENSE

Illuminated is available under the MIT license. See LICENSE for details
