# Time Space Rebuild (時空重構) — Linux Fix

> This script is intended for owners of a legitimate copy of the game
> and is solely aimed at ensuring compatibility with Linux.

The game does not officially support Linux. To run it via Proton you need to:
1. Install a 32-bit Vulkan driver (the game is 32-bit)
2. Decrypt and remux in-game videos (HLS + AES-128 is not supported by Wine Media Foundation)
3. Add a Steam launch option

[Инструкция на русском](README-RU.md)

## Requirements

- Steam with Proton (GE-Proton or Proton Experimental)
- For AMD GPU: `lib32-vulkan-radeon` (Arch) or equivalent for your distro
- For Intel GPU: `lib32-vulkan-intel` (Arch) or equivalent for your distro
- For NVIDIA GPU: `lib32-nvidia-utils`
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

Ubuntu/Debian (AMD):
```bash
sudo apt install mesa-vulkan-drivers:i386
```

### 2. Steam launch options

Steam → Right-click the game → Properties → General → Launch Options:
```
PROTON_MEDIA_USE_GST=1 %command%
```

### 3. Run the video fix script

The script automatically:
- Locates the game folder in Steam
- Creates a backup of the original video files
- Decrypts .ts segments (AES-128)
- Remuxes segments into clean MPEG-TS files
- Replaces .m3u8 files with ready-to-play videos

```bash
chmod +x fix-videos.sh
./fix-videos.sh
```

To specify a custom game path:
```bash
./fix-videos.sh /path/to/steamapps/common/時空重構
```

### 4. Launch the game

Done. Videos should play correctly.

## Reverting changes

The backup is saved as `CommonVideoClips.bak` next to `CommonVideoClips`.
To revert:
```bash
GAME="$HOME/.local/share/Steam/steamapps/common/時空重構/時空重構/時空重構_Data/StreamingAssets"
rm -rf "$GAME/CommonVideoClips"
mv "$GAME/CommonVideoClips.bak" "$GAME/CommonVideoClips"
```

You can also use Steam's "Verify integrity of game files" to restore the originals,
then run `fix-videos.sh` again.

## The problem

In-game videos are stored in HLS format (M3U8 + .ts segments) with AES-128 encryption.
Wine/Proton Media Foundation does not support HLS. Instead of video, a test pattern (color bars) is displayed.

The script decrypts the segments and remuxes them into regular MPEG-TS files
that Media Foundation (via the GStreamer backend) can play.
