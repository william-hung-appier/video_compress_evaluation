#!/bin/bash

FORMAT="csv"
THREADS_COUNT=0
MATERIALS_DIR="$(dirname "$0")/../materials"
OUT_DIR="$(dirname "$0")/../out"
PREFIX=""
CUSTOM_W=""
CUSTOM_H=""
VERBOSE="false"

for arg in "$@"; do
    case $arg in
        COMPRESS=*)
            COMPRESS_VIDEO="${arg#*=}"
            shift
            ;;
        ORIGIN=*)
            ORIGIN_VIDEO="${arg#*=}"
            shift
            ;;
        FORMAT=*)
            FORMAT="${arg#*=}"
            shift
            ;;
        THREADS=*)
            THREADS_COUNT="${arg#*=}"
            shift
            ;;
        OUT_DIR=*)
            OUT_DIR="${arg#*=}"
            shift
            ;;
        PREFIX=*)
            PREFIX="${arg#*=}"
            shift
            ;;
        CUSTOM_W=*)
            CUSTOM_W="${arg#*=}"
            shift
            ;;
        CUSTOM_H=*)
            CUSTOM_H="${arg#*=}"
            shift
            ;;
        VERBOSE=*)
            VERBOSE="${arg#*=}"
            shift
            ;;
        *)
            # Unknown option
            ;;
    esac
done

if [ -z "$COMPRESS_VIDEO" ] || [ -z "$ORIGIN_VIDEO" ]; then
    echo "Error: Missing required parameters"
    echo "Usage: $0 COMPRESS=<compress_video_file_name> ORIGIN=<origin_video_file_name> [FORMAT=csv] [THREADS=0] [CUSTOM_W=width] [CUSTOM_H=height]"
    echo ""
    echo "Examples:"
    echo "  $0 COMPRESS=prod_compress.mp4 ORIGIN=prod_origin.mp4"
    echo "  $0 COMPRESS=prod_compress.mp4 ORIGIN=prod_origin.mp4 FORMAT=json THREADS=4"
    echo "  $0 COMPRESS=bad_compress.mp4 ORIGIN=bad_origin.mp4 CUSTOM_W=1080 CUSTOM_H=1920"
    exit 1
fi

target_video="$MATERIALS_DIR/$COMPRESS_VIDEO"
reference_video="$MATERIALS_DIR/$ORIGIN_VIDEO"

if [ ! -f "$target_video" ]; then
    echo "Error: Compressed video file not found: $target_video"
    exit 1
fi

if [ ! -f "$reference_video" ]; then
    echo "Error: Origin video file not found: $reference_video"
    exit 1
fi

mkdir -p "$OUT_DIR"
if [ -n "$PREFIX" ]; then
    OUTPUT_FILE="$OUT_DIR/${PREFIX}_vmaf_score.$FORMAT"
else
    OUTPUT_FILE="$OUT_DIR/vmaf_score.$FORMAT"
fi

GREEN='\033[0;92m'
BOLD_GREEN='\033[1;92m'
RESET='\033[0m'

echo "=== Start comparing videos ==="
echo -e "Compressed: ${GREEN}${COMPRESS_VIDEO}${RESET} vs. Origin: ${GREEN}${ORIGIN_VIDEO}${RESET}"

if [ -n "$CUSTOM_W" ] && [ -n "$CUSTOM_H" ]; then
    echo "Using custom scaling: ${CUSTOM_W}x${CUSTOM_H}"
    LAVFI_FILTER="[0:v]scale=${CUSTOM_W}:${CUSTOM_H}:flags=bicubic[dist];[1:v][dist]libvmaf=log_fmt=$FORMAT:n_threads=$THREADS_COUNT:log_path=$OUTPUT_FILE"
else
    echo "Using original video sizes"
    LAVFI_FILTER="libvmaf=log_fmt=$FORMAT:n_threads=$THREADS_COUNT:log_path=$OUTPUT_FILE"
fi

if [ "$VERBOSE" = "true" ]; then
    ffmpeg -i "$target_video" -i "$reference_video" \
        -lavfi "$LAVFI_FILTER" \
        -f null - 2>&1
else
    ffmpeg -i "$target_video" -i "$reference_video" \
        -lavfi "$LAVFI_FILTER" \
        -f null - 2>&1 | grep "VMAF score:" | sed 's/.*VMAF score: //' | sed 's/itrate=.*//' | awk -v green="$BOLD_GREEN" -v reset="$RESET" '{print green "VMAF score:" reset " " $0}'
fi
