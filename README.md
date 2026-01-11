# Audio Conversion Scripts

A collection of shell scripts for converting audio files between formats with audiophile-quality settings.

## Requirements

- **ffmpeg** - Required for all conversions
  ```bash
  # macOS
  brew install ffmpeg

  # Ubuntu/Debian
  sudo apt install ffmpeg
  ```

## Scripts

### flac-to-aiff.sh

Converts FLAC files to uncompressed AIFF format with optional resampling.

**Default behavior:** Preserves original sample rate and bit depth (no downsampling).

**Options:**
| Option | Description |
|--------|-------------|
| `-r, --sample-rate <rate>` | Resample to specified rate (e.g., 44100, 48000, 96000) |
| `-b, --bit-depth <bits>` | Convert to specified bit depth (16 or 24) |
| `--redbook` | Shortcut for CD quality: 44100 Hz / 16-bit |
| `-h, --help` | Show help message |

**Usage:**
```bash
./flac-to-aiff.sh [OPTIONS] <source_folder> <destination_folder>
```

**Examples:**
```bash
# Preserve original quality (no resampling)
./flac-to-aiff.sh "./Album [FLAC]" "./Album [AIFF]"

# Convert to Red Book CD quality (44.1kHz / 16-bit)
./flac-to-aiff.sh --redbook "./Album [FLAC]" "./Album [AIFF]"

# Downsample to 48kHz / 24-bit
./flac-to-aiff.sh -r 48000 -b 24 "./Album [FLAC]" "./Album [AIFF]"

# Only change sample rate, keep original bit depth
./flac-to-aiff.sh -r 44100 "./Album [FLAC]" "./Album [AIFF]"
```

**Features:**
- Preserves metadata (artist, album, track number, title, etc.)
- Automatically detects and copies cover art
- Searches common cover art locations and filenames

## Cover Art Detection

The scripts automatically search for cover art in the following order:

1. **Root folder** - Common filenames:
   - `cover.jpg`, `folder.jpg`, `front.jpg`, `album.jpg`, `artwork.jpg`
   - Also checks `.png` variants and case variations

2. **Subfolders** - Common artwork folders:
   - `Covers/`, `Cover/`, `Artwork/`, `Scans/`
   - Looks for front cover first, then falls back to any image

3. **Fallback** - Any `.jpg` or `.png` in the source folder

The cover is saved as `cover.jpg` in the destination folder.

## Common Sample Rates

| Rate | Use Case |
|------|----------|
| 44100 Hz | CD quality (Red Book) |
| 48000 Hz | DVD, digital video |
| 88200 Hz | 2x CD (high-res audio) |
| 96000 Hz | DVD-Audio, high-res streaming |
| 176400 Hz | 4x CD (studio master) |
| 192000 Hz | Studio master, archival |

## License

MIT
