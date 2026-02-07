# Freelancer Installer for Linux

Automated Freelancer installation script with support for HD Edition and Discovery Mod on multiple Linux systems.

## Supported Systems

- **CachyOS** (Arch-based with pacman)
- **Steam Deck** (SteamOS/Arch-based with read-only filesystem)
- **Arch Linux**
- **Ubuntu/Debian**

## Features

- 🎨 **Freelancer HD Edition** - Enhanced graphics mod
- 🚀 **Discovery Mod** - Fan-made total conversion mod
- 📥 **Automatic Downloads** - Parallel downloads for faster installation
- 🔄 **Mode Selector** - Choose which game version to play
- 🛡️ **No-CD Patch** - Bypass DRM/SafeDisc protection
- 🍷 **Wine Integration** - Automatic Wine prefix setup and configuration

## Installation

### On CachyOS

```bash
./play_freelancer.sh
```

The script will automatically:

1. Install required packages via pacman
2. Download Freelancer ISO, HD Mod, Discovery Mod, and No-CD patch
3. Set up Wine prefix and install silently
4. Show a menu to select which game version to play

### On Steam Deck

**Prerequisites:**

- Boot into Desktop Mode
- Open Terminal
- Navigate to this directory

```bash
./play_freelancer.sh
```

On Steam Deck, the script will:

1. Install required packages via `rpm-ostree` (SteamOS package manager)
2. Download Freelancer ISO, HD Mod, Discovery Mod, and No-CD patch
3. Set up Wine prefix and install silently
4. Show a menu to select which game version to play

**Important for Steam Deck:**

- The `rpm-ostree install` command may require a **system restart** after first run
- If "wine not found" error appears after restart, the packages should now be available
- The script will automatically find Proton's wine as fallback
- If still not found after restart, you may need to manually restart or check if packages were installed correctly

### On Ubuntu/Debian

```bash
./play_freelancer.sh
```

The script will automatically install packages via apt-get.

## File Structure

```
./
├── play_freelancer.sh      # Launcher (auto-installs if needed)
├── install_freelancer.sh   # Installation script
├── .gitignore             # Git ignore rules
├── download/              # Downloaded files (ISO, mods, patches)
└── wine-freelancer/       # Wine prefix with installed game
```

## Usage

### Launch the Game

```bash
./play_freelancer.sh
```

On first run, it will install everything automatically.

### Menu

After installation, you'll see:

```
=== Freelancer Launcher ===
Welchen Modus möchtest du spielen?
  [1] Freelancer HD Edition (Vanilla)
  [2] Discovery Mod

Auswahl [1-2]:
```

Select your preferred game version.

### Reinstall / Clean Installation

```bash
rm -rf wine-freelancer download
./play_freelancer.sh
```

## System Detection

The scripts automatically detect your system and configure accordingly:

- **CachyOS/Arch**: Uses `pacman` for dependencies
- **Steam Deck (SteamOS)**: Uses `rpm-ostree install` for dependencies
- **Ubuntu/Debian**: Uses `apt-get` for dependencies
- **Unknown**: Guides you to install tools manually

## Troubleshooting

### "Read-only file system" error

This should not occur anymore as the script uses `rpm-ostree install` on Steam Deck to properly install packages.

If you still get this error:

- Make sure you're running from `$HOME` (not from system directories)
- Check that `/var/lib/rpm-ostree` is writable
- You may need to use `sudo` when running the script

### Wine tools not found

The script automatically searches for wine in:

1. System PATH (if already installed)
2. Steam Deck Proton locations (if on Steam Deck)
3. Freshly installed rpm-ostree packages

**On Steam Deck:**

- The script will try to find Proton's wine automatically
- If `rpm-ostree install` was just run, a **system restart may be required** for packages to become available
- After restart, try running `./play_freelancer.sh` again

**On other systems:**

- Make sure wine is properly installed: `pacman -S wine` (Arch) or `apt-get install wine` (Ubuntu)
- Run the script with proper permissions (may need `sudo`)

### Game doesn't launch

Check the console output for error messages. Common issues:

- Wine prefix not initialized properly
- Missing No-CD patch
- Game directory missing

### Discovery Mod shows black screen

The launcher uses `DSLauncher.exe` which provides a proper launcher interface.

## Configuration

Edit the URLs in `install_freelancer.sh` to use different versions:

```bash
FREELANCER_ISO_URL="..."
HD_MOD_URL="..."
DISCOVERY_MOD_URL="..."
```

## License

These scripts are provided as-is for personal use. Freelancer and mods are property of their respective creators.

## Credits

- **Freelancer HD Edition**: https://github.com/FLHDE/freelancer-hd-edition
- **Discovery Mod**: https://discoverygc.com/
- **No-CD Patch**: From abandonware archives
