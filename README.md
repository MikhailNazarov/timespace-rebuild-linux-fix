# Time Space Rebuild (時空重構) — Linux Fix

> This script is intended for owners of a legitimate copy of the game
> and is solely aimed at ensuring compatibility with Linux.

The game does not officially support Linux. It runs via Proton, but in-game videos
(HLS + AES-128 encrypted) do not play — you get a test pattern (color bars) or a crash.

This script decrypts and remuxes the videos into plain MPEG-TS files that GE-Proton can play.

[Инструкция на русском](README-RU.md)

## Requirements

- Steam with **GE-Proton** (install via [ProtonUp-Qt](https://github.com/DavidoTek/ProtonUp-Qt) or manually from [GE-Proton releases](https://github.com/GloriousEggroll/proton-ge-custom/releases))
- 32-bit Vulkan driver (the game is 32-bit)
- `ffmpeg` and `openssl` (usually already installed)

## Installation

### 1. Install 32-bit Vulkan driver

Arch Linux (AMD):
```bash
sudo pacman -S lib32-vulkan-radeon
```

Arch Linux (Intel):
```bash
sudo pacman -S lib32-vulkan-intel
```

Arch Linux (NVIDIA):
```bash
sudo pacman -S lib32-nvidia-utils
```

Ubuntu/Debian (AMD/Intel):
```bash
sudo apt install mesa-vulkan-drivers:i386
```

Ubuntu/Debian (NVIDIA):
```bash
# Find your driver version: nvidia-smi | head -3
sudo apt install libnvidia-gl-560:i386
```

### 2. Run the video fix script

The script automatically:
- Locates the game folder in Steam
- Creates a backup of the original video files
- Decrypts AES-128 encrypted .ts segments
- Remuxes segments into clean MPEG-TS files
- Replaces .m3u8 playlists with ready-to-play videos

```bash
git clone https://github.com/MikhailNazarov/timespace-rebuild-linux-fix.git
cd timespace-rebuild-linux-fix
chmod +x fix-videos.sh
./fix-videos.sh
```

To specify a custom game path:
```bash
./fix-videos.sh /path/to/steamapps/common/時空重構
```

### 3. Select GE-Proton and launch

In Steam: right-click the game → Properties → Compatibility → check "Force the use of a specific Steam Play compatibility tool" → select **GE-Proton**.

## Reverting changes

The backup is saved as `CommonVideoClips.bak` next to `CommonVideoClips`.
To revert:
```bash
GAME="$HOME/.local/share/Steam/steamapps/common/時空重構/時空重構/時空重構_Data/StreamingAssets"
rm -rf "$GAME/CommonVideoClips"
mv "$GAME/CommonVideoClips.bak" "$GAME/CommonVideoClips"
```

You can also use Steam's "Verify integrity of game files" to restore the originals.

## The problem

The game uses [AVProVideo](https://renderheads.com/products/avpro-video/) for video playback via Windows Media Foundation.
In-game videos are stored as HLS playlists (`.m3u8` + `.ts` segments) encrypted with AES-128.

Wine/Proton's Media Foundation implementation cannot handle this format:
- **Proton Experimental**: shows a 320×240 test pattern (SMPTE color bars) instead of video
- **GE-Proton**: crashes when attempting to play encrypted HLS

The script decrypts the segments and assembles them into plain MPEG-TS files
that Media Foundation in GE-Proton can play natively.
