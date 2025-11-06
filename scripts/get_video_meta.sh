#!/bin/bash

MATERIALS_DIR="$(dirname "$0")/../materials"
PREFIX=""

for arg in "$@"; do
    case $arg in
        MATERIALS_DIR=*)
            MATERIALS_DIR="${arg#*=}"
            shift
            ;;
        PREFIX=*)
            PREFIX="${arg#*=}"
            shift
            ;;
        *)
            # Unknown option
            ;;
    esac
done

# Validate required parameters
if [ -z "$PREFIX" ]; then
    echo "Error: Missing required parameter PREFIX"
    echo "Usage: $0 PREFIX=<prefix> [MATERIALS_DIR=path]"
    echo ""
    echo "Examples:"
    echo "  $0 PREFIX=prod"
    echo "  $0 PREFIX=prod MATERIALS_DIR=/path/to/materials"
    exit 1
fi

# Color codes
GREEN='\033[0;92m'
BOLD_GREEN='\033[1;92m'
RESET='\033[0m'

origin_file="$MATERIALS_DIR/${PREFIX}_origin.mp4"
compress_file="$MATERIALS_DIR/${PREFIX}_compress.mp4"

echo -e ">>> Pair: ${BOLD_GREEN}${PREFIX}${RESET} <<<"
echo ""

# Check if origin file exists
if [ ! -f "$origin_file" ]; then
    echo "Warning: $origin_file not found, skipping..."
    exit 1
fi

# Show origin metadata
echo -e "${GREEN}[ORIGIN]${RESET}"
ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height,r_frame_rate \
    -of default=noprint_wrappers=1 "$origin_file"
echo ""

# Show compressed metadata
if [ -f "$compress_file" ]; then
    echo -e "${GREEN}[COMPRESSED]${RESET}"
    ffprobe -v error -select_streams v:0 \
        -show_entries stream=width,height,r_frame_rate \
        -of default=noprint_wrappers=1 "$compress_file"
else
    echo "  [COMPRESSED] - NOT FOUND"
fi
echo ""
