#!/usr/bin/env bash

# Script to install asdf plugins and set up default versions

# Check if asdf is installed
if ! command -v asdf &> /dev/null; then
  echo "Error: asdf is not installed. Please install it first."
  exit 1
fi

echo "Setting up asdf plugins and versions..."

# Add plugins for common development languages
asdf plugin add nodejs
asdf plugin add python

# Install latest versions of each plugin
echo "Installing latest versions of plugins..."

# Node.js 
echo "Installing Node.js latest LTS version..."
asdf install nodejs lts
asdf set nodejs lts

# Python
echo "Installing Python latest version..."
asdf install python latest
asdf set python latest

# Install global npm packages
echo "Installing global npm packages..."
npm install -g better-commits tldr rimraf

echo "asdf setup complete! The following versions are now available:"
asdf current

# Reshim asdf to make sure all binaries are accessible
asdf reshim