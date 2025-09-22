#!/usr/bin/env bash

# Script to install mise and set up default tool versions

# Check if mise is installed
if ! command -v mise &> /dev/null; then
  echo "Error: mise is not installed. Please install it first with: brew install mise"
  exit 1
fi

echo "Setting up mise tools and versions..."

# Install and set global versions for common development languages
echo "Installing Node.js LTS version..."
mise use --global node@lts

echo "Installing Python latest version..."
mise use --global python@3

# Install global npm packages
echo "Installing global npm packages..."
npm install -g better-commits tldr rimraf

echo "mise setup complete! The following versions are now available:"
mise ls

echo ""
echo "To activate mise in your current shell, run:"
echo "eval \"\$(mise activate \$(basename \$SHELL))\""