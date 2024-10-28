#!/bin/bash

# Function to install a package
install_package() {
  local package="$1"
  
  # Detect package manager and install the package
  if command -v pkg &> /dev/null; then
    pkg update && pkg install -y "$package"
  elif command -v dnf &> /dev/null; then
    sudo dnf install -y "$package"
  elif command -v pacman &> /dev/null; then
    sudo pacman -Sy --noconfirm "$package"
  elif command -v zypper &> /dev/null; then
    sudo zypper install -y "$package"
  elif command -v yum &> /dev/null; then
    sudo yum install -y "$package"
  elif command -v apk &> /dev/null; then
    sudo apk add "$package"
  elif command -v apt &> /dev/null; then  # Termux package manager
    sudo apt update && sudo apt install -y "$package"
  else
    echo "Error: Unsupported package manager. Please install $package manually."
    exit 1
  fi
}

# Check for ffmpeg and zip binaries and install if missing
if ! command -v ffmpeg &> /dev/null; then
    echo "ffmpeg not found. Installing..."
    install_package "ffmpeg" || { echo "Failed to install ffmpeg."; exit 1; }
fi

if ! command -v zip &> /dev/null; then
    echo "zip not found. Installing..."
    install_package "zip" || { echo "Failed to install zip."; exit 1; }
fi

# Prompt for video parameters
read -p "Enter video path (e.g., /path/to/video.mp4): " video
if [ ! -f "$video" ]; then
    echo "Error: Video file does not exist."
    exit 1
fi

read -p "Enter output resolution (e.g., 1080x1920): " resolution
width=$(echo "$resolution" | cut -d'x' -f1)
height=$(echo "$resolution" | cut -d'x' -f2)

read -p "Enter frame rate (fps, max 45): " fps
fps=$(( fps > 45 ? 45 : fps ))

read -p "Enter output path (e.g., /path/to/output.zip): " output_path

# Temporary directory setup for processing
TMP_DIR="~/bootanim"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR/frames" "$TMP_DIR/result"
desc_file="$TMP_DIR/result/desc.txt"
output_zip="$output_path"

# Generate frames with ffmpeg
ffmpeg -i "$video" -vf "scale=${width}:${height}" "$TMP_DIR/frames/frame%04d.jpg" || {
    echo "Error generating frames from video."
    exit 1
}

# Count frames
frame_count=$(ls -1 "$TMP_DIR/frames" | wc -l)
if [ "$frame_count" -eq 0 ]; then
    echo "No frames generated. Exiting."
    exit 1
fi
echo "Processed $frame_count frames."

# Create desc.txt
echo "$width $height $fps" > "$desc_file"
echo "p 1 0 frames" >> "$desc_file"

# Pack frames into parts if more than 400 frames
max_frames=400
part_index=0
frame_index=0

mkdir -p "$TMP_DIR/result/part$part_index"
for frame in "$TMP_DIR/frames"/*.jpg; do
  mv "$frame" "$TMP_DIR/result/part$part_index/"
  frame_index=$((frame_index + 1))

  if [ "$frame_index" -ge "$max_frames" ]; then
    frame_index=0
    part_index=$((part_index + 1))
    mkdir -p "$TMP_DIR/result/part$part_index"
  fi
done

# Append part entries in desc.txt
for i in $(seq 0 "$part_index"); do
  echo "p 1 0 part$i" >> "$desc_file"
done

# Zip the bootanimation
echo "Creating bootanimation.zip..."
cd "$TMP_DIR/result" || { echo "Error accessing result directory."; exit 1; }
zip -r "$output_zip" . || { echo "Error creating zip file."; exit 1; }
echo "Bootanimation created at $output_zip"

# Clean up
rm -rf "$TMP_DIR"
echo "Process complete."