#!/bin/bash

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script requires sudo privileges to modify Bear's theme files."
    echo "Please run with sudo: sudo $0"
    exit 1
fi

# Source and destination paths
SOURCE_THEME="$(dirname "$0")/Panic Mode.theme"
DEST_DIR="/Applications/Bear.app/Contents/Frameworks/BearCore.framework/Versions/A/Resources"
DEST_THEME="$DEST_DIR/Panic Mode.theme"
BACKUP_THEME="$DEST_DIR/Panic Mode.theme.backup"

# Check if source theme exists
if [ ! -f "$SOURCE_THEME" ]; then
    echo "Error: Source theme file not found at $SOURCE_THEME"
    exit 1
fi

# Check if Bear app exists
if [ ! -d "/Applications/Bear.app" ]; then
    echo "Error: Bear.app not found at /Applications/Bear.app"
    exit 1
fi

# Check if destination directory exists
if [ ! -d "$DEST_DIR" ]; then
    echo "Error: Destination directory not found at $DEST_DIR"
    exit 1
fi

# Create backup of existing theme if it exists
if [ -f "$DEST_THEME" ]; then
    echo "Creating backup of existing theme..."
    cp "$DEST_THEME" "$BACKUP_THEME"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create backup"
        exit 1
    fi
    echo "Backup created at $BACKUP_THEME"
fi

# Copy new theme
echo "Installing new theme..."
cp "$SOURCE_THEME" "$DEST_THEME"
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy theme file"
    exit 1
fi

echo "Theme successfully installed!"
echo "You may need to restart Bear for changes to take effect."
