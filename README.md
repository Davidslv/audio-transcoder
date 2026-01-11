# Audio Transcoder

Shell scripts for converting audio files between lossless formats with audiophile-quality settings.

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

---

### wav-to-aiff.sh

Converts WAV files to uncompressed AIFF format with optional resampling.

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
./wav-to-aiff.sh [OPTIONS] <source_folder> <destination_folder>
```

**Examples:**
```bash
# Preserve original quality (no resampling)
./wav-to-aiff.sh "./Album [WAV]" "./Album [AIFF]"

# Convert to Red Book CD quality (44.1kHz / 16-bit)
./wav-to-aiff.sh --redbook "./Album [WAV]" "./Album [AIFF]"

# Downsample to 48kHz / 24-bit
./wav-to-aiff.sh -r 48000 -b 24 "./Album [WAV]" "./Album [AIFF]"
```

**Features:**
- Preserves metadata (artist, album, track number, title, etc.)
- Automatically detects and copies cover art
- Searches common cover art locations and filenames

---

### dsd-to-aiff.sh

Converts DSD files (.dsf, .dff) to uncompressed AIFF format.

**Default behavior:** Outputs 176.4kHz / 24-bit (optimal for DSD conversion).

**Supported DSD formats:**
| Format | Sample Rate | Status |
|--------|-------------|--------|
| DSD64 | 2.8 MHz | ✓ Supported |
| DSD128 | 5.6 MHz | ✓ Supported |
| DSD256 | 11.2 MHz | ✓ Supported |
| DSD512 | 22.5 MHz | ✓ Supported |

DSD is 1-bit audio at very high sample rates. Converting to PCM requires decimation. Higher output sample rates preserve more of the original high-frequency content.

**Options:**
| Option | Description |
|--------|-------------|
| `-r, --sample-rate <rate>` | Output sample rate (default: 176400) |
| `-b, --bit-depth <bits>` | Output bit depth (16 or 24, default: 24) |
| `--redbook` | Shortcut for CD quality: 44100 Hz / 16-bit |
| `-h, --help` | Show help message |

**Usage:**
```bash
./dsd-to-aiff.sh [OPTIONS] <source_folder> <destination_folder>
```

**Examples:**
```bash
# Default: 176.4kHz / 24-bit (best quality for DSD)
./dsd-to-aiff.sh "./Album [DSD]" "./Album [AIFF]"

# Convert to Red Book CD quality (44.1kHz / 16-bit)
./dsd-to-aiff.sh --redbook "./Album [DSD]" "./Album [AIFF]"

# Custom: 88.2kHz / 24-bit
./dsd-to-aiff.sh -r 88200 -b 24 "./Album [DSD]" "./Album [AIFF]"
```

**Recommended output rates for DSD:**
| Rate | Quality |
|------|---------|
| 176400 Hz | Best - preserves most DSD detail |
| 88200 Hz | Good - smaller files |
| 44100 Hz | Maximum compatibility |

**Features:**
- Supports .dsf and .dff formats
- Preserves metadata
- Automatically detects and copies cover art

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
