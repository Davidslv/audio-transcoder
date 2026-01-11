#!/bin/bash
#
# DSD to AIFF Converter
# Converts DSD files (.dsf, .dff) to uncompressed AIFF format
# Preserves metadata and copies cover art
#
# Usage: dsd-to-aiff.sh [OPTIONS] <source_folder> <destination_folder>
#
# Options:
#   -r, --sample-rate <rate>   Output sample rate (e.g., 44100, 88200, 176400)
#                              Default: 176400 (4x CD, recommended for DSD)
#   -b, --bit-depth <bits>     Output bit depth (16 or 24). Default: 24
#   --redbook                  Shortcut for CD quality: 44100 Hz / 16-bit
#   -h, --help                 Show this help message
#
# DSD files are 1-bit audio at very high sample rates (2.8-11.2 MHz).
# Converting to PCM requires decimation. Higher output sample rates
# preserve more of the original high-frequency content.
#
# Recommended output rates:
#   - 176400 Hz (4x CD) - Best quality, preserves most DSD detail
#   - 88200 Hz (2x CD)  - Good quality, smaller files
#   - 44100 Hz (CD)     - Maximum compatibility
#
# Examples:
#   # Default: 176.4kHz / 24-bit (best quality)
#   dsd-to-aiff.sh "./Album [DSD]" "./Album [AIFF]"
#
#   # Convert to Red Book CD quality (44.1kHz / 16-bit)
#   dsd-to-aiff.sh --redbook "./Album [DSD]" "./Album [AIFF]"
#
#   # Custom: 88.2kHz / 24-bit
#   dsd-to-aiff.sh -r 88200 -b 24 "./Album [DSD]" "./Album [AIFF]"
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Defaults for DSD conversion (higher rates preserve more detail)
SAMPLE_RATE="176400"
BIT_DEPTH="24"

usage() {
    echo "Usage: $0 [OPTIONS] <source_folder> <destination_folder>"
    echo ""
    echo "Converts all DSD files (.dsf, .dff) in source_folder to AIFF format."
    echo "Default output: 176.4kHz / 24-bit (optimal for DSD conversion)."
    echo ""
    echo "Options:"
    echo "  -r, --sample-rate <rate>   Output sample rate in Hz"
    echo "                             Recommended: 176400, 88200, or 44100"
    echo "  -b, --bit-depth <bits>     Output bit depth (16 or 24)"
    echo "  --redbook                  Shortcut for CD quality: 44100 Hz / 16-bit"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Default: 176.4kHz / 24-bit (best quality)"
    echo "  $0 \"./Album [DSD]\" \"./Album [AIFF]\""
    echo ""
    echo "  # Convert to Red Book CD quality"
    echo "  $0 --redbook \"./Album [DSD]\" \"./Album [AIFF]\""
    echo ""
    echo "  # Custom: 88.2kHz / 24-bit"
    echo "  $0 -r 88200 -b 24 \"./Album [DSD]\" \"./Album [AIFF]\""
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

# Validate bit depth
if [ "$BIT_DEPTH" != "16" ] && [ "$BIT_DEPTH" != "24" ]; then
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
FFMPEG_OPTS=("-ar" "$SAMPLE_RATE")

if [ "$BIT_DEPTH" = "16" ]; then
    FFMPEG_OPTS+=("-sample_fmt" "s16" "-c:a" "pcm_s16be")
else
    FFMPEG_OPTS+=("-sample_fmt" "s32" "-c:a" "pcm_s24be")
fi

FFMPEG_OPTS+=("-write_id3v2" "1")

# Format description
FORMAT_DESC="${SAMPLE_RATE} Hz / ${BIT_DEPTH}-bit"

echo -e "${GREEN}DSD to AIFF Converter${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Source:      $SOURCE_DIR"
echo "Destination: $DEST_DIR"
echo -e "Format:      AIFF ${BLUE}${FORMAT_DESC}${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Count DSD files (.dsf and .dff)
DSD_COUNT=$(find "$SOURCE_DIR" -maxdepth 1 \( -iname "*.dsf" -o -iname "*.dff" \) -type f | wc -l | tr -d ' ')

if [ "$DSD_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}Warning: No DSD files (.dsf, .dff) found in source folder${NC}"
    exit 0
fi

echo -e "Found ${GREEN}$DSD_COUNT${NC} DSD files to convert"
echo ""

# Convert each DSD file
CURRENT=0
for dsd_file in "$SOURCE_DIR"/*.dsf "$SOURCE_DIR"/*.dff "$SOURCE_DIR"/*.DSF "$SOURCE_DIR"/*.DFF; do
    [ -e "$dsd_file" ] || continue

    CURRENT=$((CURRENT + 1))
    filename=$(basename "$dsd_file")
    filename_noext="${filename%.*}"
    output_file="$DEST_DIR/$filename_noext.aiff"

    echo -e "[${CURRENT}/${DSD_COUNT}] Converting: ${YELLOW}$filename_noext${NC}"

    if ffmpeg -y -i "$dsd_file" "${FFMPEG_OPTS[@]}" "$output_file" 2>/dev/null; then
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
    COVER_FOLDERS=("Covers" "covers" "Cover" "cover" "Artwork" "artwork" "Scans" "scans")

    for folder in "${COVER_FOLDERS[@]}"; do
        if [ -d "$SOURCE_DIR/$folder" ]; then
            for pattern in "front.jpg" "Front.jpg" "FRONT.jpg" "cover.jpg" "Cover.jpg"; do
                cover_file=$(find "$SOURCE_DIR/$folder" -maxdepth 1 -iname "$pattern" -type f | head -1)
                if [ -n "$cover_file" ]; then
                    cp "$cover_file" "$DEST_DIR/cover.jpg"
                    echo -e "${GREEN}✓ Copied cover art from $folder/$(basename "$cover_file")${NC}"
                    COVER_FOUND=true
                    break 2
                fi
            done

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

# Last resort: any image file
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
