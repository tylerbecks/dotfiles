# Sound Effects

This directory contains sound effect files used by the `sfx` command.

## Usage

Once the sound files are in place and `mpv` is installed, you can:

```bash
# Play a sound effect directly
sfx good
sfx bad

# Use boop to play sound based on last command's exit status
true && boop   # plays good.ogg
false && boop  # plays bad.ogg
```

## Installation

1. Install mpv: `brew install mpv` (or run `brew.sh`)
2. Place your `.ogg` sound files in this directory
3. Source your shell config: `source ~/.zshrc`
