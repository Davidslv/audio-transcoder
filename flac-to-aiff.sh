#!/bin/bash
#
# FLAC to AIFF Converter
# Converts FLAC files to uncompressed AIFF format
# Preserves metadata and copies cover art
#
# Usage: flac-to-aiff.sh [OPTIONS] <source_folder> <destination_folder>
#
# Options:
#   -r, --sample-rate <rate>   Resample to specified rate (e.g., 44100, 48000, 96000)
#   -b, --bit-depth <bits>     Convert to specified bit depth (16 or 24)
#   --redbook                  Shortcut for CD quality: 44100 Hz / 16-bit
#   -h, --help                 Show this help message
#
# Examples:
#   # Preserve original quality (no resampling)
#   flac-to-aiff.sh "./Album [FLAC]" "./Album [AIFF]"
#
#   # Convert to Red Book CD quality (44.1kHz / 16-bit)
#   flac-to-aiff.sh --redbook "./Album [FLAC]" "./Album [AIFF]"
#
#   # Custom sample rate and bit depth
#   flac-to-aiff.sh -r 48000 -b 24 "./Album [FLAC]" "./Album [AIFF]"
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default: no resampling (empty means preserve original)
SAMPLE_RATE=""
BIT_DEPTH=""

usage() {
    echo "Usage: $0 [OPTIONS] <source_folder> <destination_folder>"
    echo ""
    echo "Converts all FLAC files in source_folder to uncompressed AIFF format."
    echo "By default, preserves original sample rate and bit depth."
    echo ""
    echo "Options:"
    echo "  -r, --sample-rate <rate>   Resample to specified rate in Hz"
    echo "                             Common values: 44100, 48000, 88200, 96000, 176400, 192000"
    echo "  -b, --bit-depth <bits>     Convert to specified bit depth (16 or 24)"
    echo "  --redbook                  Shortcut for CD quality: 44100 Hz / 16-bit"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Preserve original quality"
    echo "  $0 \"./Album [FLAC]\" \"./Album [AIFF]\""
    echo ""
    echo "  # Convert to Red Book CD quality"
    echo "  $0 --redbook \"./Album [FLAC]\" \"./Album [AIFF]\""
    echo ""
    echo "  # Downsample to 48kHz / 24-bit"
    echo "  $0 -r 48000 -b 24 \"./Album [FLAC]\" \"./Album [AIFF]\""
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--sample-rate)
            SAMPLE_RATE="$2"
            shift 2
            ;;
        -b|--bit-depth)
            BIT_DEPTH="$2"
            shift 2
            ;;
        --redbook)
            SAMPLE_RATE="44100"
            BIT_DEPTH="16"
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo -e "${RED}Error: Unknown option $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Remaining arguments are source and destination
if [ $# -ne 2 ]; then
    echo -e "${RED}Error: Source and destination folders are required${NC}"
    echo "Use -h or --help for usage information"
    exit 1
fi

SOURCE_DIR="$1"
DEST_DIR="$2"

# Validate bit depth if specified
if [ -n "$BIT_DEPTH" ] && [ "$BIT_DEPTH" != "16" ] && [ "$BIT_DEPTH" != "24" ]; then
    echo -e "${RED}Error: Bit depth must be 16 or 24${NC}"
    exit 1
fi

# Check if source exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Error: Source folder does not exist: $SOURCE_DIR${NC}"
    exit 1
fi

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${RED}Error: ffmpeg is not installed. Please install it first.${NC}"
    echo "  macOS: brew install ffmpeg"
    echo "  Ubuntu: sudo apt install ffmpeg"
    exit 1
fi

# Create destination folder
mkdir -p "$DEST_DIR"

# Build ffmpeg audio options
FFMPEG_OPTS=()

if [ -n "$SAMPLE_RATE" ]; then
    FFMPEG_OPTS+=("-ar" "$SAMPLE_RATE")
fi

if [ "$BIT_DEPTH" = "16" ]; then
    FFMPEG_OPTS+=("-sample_fmt" "s16" "-c:a" "pcm_s16be")
elif [ "$BIT_DEPTH" = "24" ]; then
    FFMPEG_OPTS+=("-sample_fmt" "s32" "-c:a" "pcm_s24be")
else
    # Default: preserve bit depth, use 24-bit container (handles both 16 and 24 bit sources)
    FFMPEG_OPTS+=("-c:a" "pcm_s24be")
fi

FFMPEG_OPTS+=("-write_id3v2" "1")

# Determine format description
if [ -n "$SAMPLE_RATE" ] && [ -n "$BIT_DEPTH" ]; then
    FORMAT_DESC="${SAMPLE_RATE} Hz / ${BIT_DEPTH}-bit"
elif [ -n "$SAMPLE_RATE" ]; then
    FORMAT_DESC="${SAMPLE_RATE} Hz / original bit depth"
elif [ -n "$BIT_DEPTH" ]; then
    FORMAT_DESC="original sample rate / ${BIT_DEPTH}-bit"
else
    FORMAT_DESC="original quality (no resampling)"
fi

echo -e "${GREEN}FLAC to AIFF Converter${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Source:      $SOURCE_DIR"
echo "Destination: $DEST_DIR"
echo -e "Format:      AIFF ${BLUE}${FORMAT_DESC}${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Count FLAC files
FLAC_COUNT=$(find "$SOURCE_DIR" -maxdepth 1 -name "*.flac" -type f | wc -l | tr -d ' ')

if [ "$FLAC_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}Warning: No FLAC files found in source folder${NC}"
    exit 0
fi

echo -e "Found ${GREEN}$FLAC_COUNT${NC} FLAC files to convert"
echo ""

# Convert each FLAC file
CURRENT=0
for flac_file in "$SOURCE_DIR"/*.flac; do
    [ -e "$flac_file" ] || continue

    CURRENT=$((CURRENT + 1))
    filename=$(basename "$flac_file" .flac)
    output_file="$DEST_DIR/$filename.aiff"

    echo -e "[${CURRENT}/${FLAC_COUNT}] Converting: ${YELLOW}$filename${NC}"

    if ffmpeg -y -i "$flac_file" "${FFMPEG_OPTS[@]}" "$output_file" 2>/dev/null; then
        echo -e "       ${GREEN}✓ Done${NC}"
    else
        echo -e "       ${RED}✗ Failed${NC}"
    fi
done

echo ""

# Copy cover art
echo "Looking for cover art..."
COVER_FOUND=false

# Common cover art filenames to look for
COVER_PATTERNS=(
    "cover.jpg" "cover.png" "Cover.jpg" "Cover.png"
    "folder.jpg" "folder.png" "Folder.jpg" "Folder.png"
    "front.jpg" "front.png" "Front.jpg" "Front.png" "FRONT.jpg" "FRONT.png"
    "album.jpg" "album.png" "Album.jpg" "Album.png"
    "artwork.jpg" "artwork.png" "Artwork.jpg" "Artwork.png"
)

# Check root of source folder
for pattern in "${COVER_PATTERNS[@]}"; do
    if [ -f "$SOURCE_DIR/$pattern" ]; then
        cp "$SOURCE_DIR/$pattern" "$DEST_DIR/cover.jpg"
        echo -e "${GREEN}✓ Copied cover art: $pattern${NC}"
        COVER_FOUND=true
        break
    fi
done

# If not found, check common subfolders
if [ "$COVER_FOUND" = false ]; then
    COVER_FOLDERS=("Covers" "covers" "Cover" "cover" "Artwork" "artwork" "Scans" "scans" "COVER FRONT BACK CD" "Cover Front Back 2cd")

    for folder in "${COVER_FOLDERS[@]}"; do
        if [ -d "$SOURCE_DIR/$folder" ]; then
            # Look for front cover first
            for pattern in "front.jpg" "Front.jpg" "FRONT.jpg" "cover.jpg" "Cover.jpg" "*.a.jpg" "*.a.mini.jpg"; do
                cover_file=$(find "$SOURCE_DIR/$folder" -maxdepth 1 -iname "$pattern" -type f | head -1)
                if [ -n "$cover_file" ]; then
                    cp "$cover_file" "$DEST_DIR/cover.jpg"
                    echo -e "${GREEN}✓ Copied cover art from $folder/$(basename "$cover_file")${NC}"
                    COVER_FOUND=true
                    break 2
                fi
            done

            # Fallback: any jpg in the folder
            if [ "$COVER_FOUND" = false ]; then
                cover_file=$(find "$SOURCE_DIR/$folder" -maxdepth 1 -iname "*.jpg" -type f | head -1)
                if [ -n "$cover_file" ]; then
                    cp "$cover_file" "$DEST_DIR/cover.jpg"
                    echo -e "${GREEN}✓ Copied cover art from $folder/$(basename "$cover_file")${NC}"
                    COVER_FOUND=true
                    break
                fi
            fi
        fi
    done
fi

# Last resort: any image file with album name pattern
if [ "$COVER_FOUND" = false ]; then
    cover_file=$(find "$SOURCE_DIR" -maxdepth 1 \( -iname "*.jpg" -o -iname "*.png" \) -type f | head -1)
    if [ -n "$cover_file" ]; then
        cp "$cover_file" "$DEST_DIR/cover.jpg"
        echo -e "${GREEN}✓ Copied cover art: $(basename "$cover_file")${NC}"
        COVER_FOUND=true
    fi
fi

if [ "$COVER_FOUND" = false ]; then
    echo -e "${YELLOW}⚠ No cover art found${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Conversion complete!${NC}"
echo "Output: $DEST_DIR"
echo ""

# Show output stats
AIFF_COUNT=$(find "$DEST_DIR" -name "*.aiff" -type f | wc -l | tr -d ' ')
TOTAL_SIZE=$(du -sh "$DEST_DIR" | cut -f1)
echo "Files converted: $AIFF_COUNT"
echo "Total size: $TOTAL_SIZE"
