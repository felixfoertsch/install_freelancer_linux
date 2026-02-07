#!/usr/bin/env bash
set -euo pipefail

### ===== Konfiguration =====

# Versions-URLs
FREELANCER_ISO_URL="https://d1.xp.myabandonware.com/t/9364bcde-6c90-4db1-9bfd-4690f2714eca/Freelancer_Win_EN_ISO.zip"
FREELANCER_NOCD_URL="https://d1.xp.myabandonware.com/t/c7feba8f-e725-44fe-a09c-8a4d3b7bb86c/Freelancer_NoCD_Win_EN.zip"
HD_MOD_URL="https://github.com/FLHDE/freelancer-hd-edition/releases/download/0.7.1/FreelancerHDESetup_v0_7_1_1.exe"
DISCOVERY_MOD_URL="https://discoverygc.com/files/discovery_5.3.2.exe"

# Verzeichnisse
WINEPREFIX="./wine-freelancer"
WINEARCH="win64"
WINEDEBUG=-all
WORKDIR="."
DOWNLOAD_DIR="./download"
MOUNT_DIR="./mount_temp"

### ===== Hilfsfunktionen =====

log() { echo -e "[*] $*"; }
err() { echo -e "[!] $*" >&2; exit 1; }

### ===== Pakete installieren =====

log "Installiere benötigte Pakete..."
sudo pacman -S --needed --noconfirm wine winetricks wget wine-gecko wine-mono fuseiso

### ===== Wineprefix vorbereiten =====

WORKDIR_ABS="$(cd "$WORKDIR" && pwd)"
WINEPREFIX="$WORKDIR_ABS/wine-freelancer"

log "Erstelle Wineprefix: $WINEPREFIX"
export WINEPREFIX
export WINEARCH
export WINEDEBUG

if [[ ! -d "$WINEPREFIX" ]]; then
  wineboot -u || true
fi

log "Installiere Winetricks..."
winetricks -q d3dx9 vcrun6 corefonts gdiplus msls31 riched20 || log "Winetricks-Warnungen ignorierbar."

### ===== Verzeichnisse erstellen =====

mkdir -p "$DOWNLOAD_DIR"

log "=== Schritt 1: Freelancer ISO ==="

ISO_FILE=$(find . -maxdepth 2 -type f -name "*.iso" | head -n 1)

if [[ -z "$ISO_FILE" ]]; then
  if [[ ! -f "$DOWNLOAD_DIR/freelancer_iso.zip" ]]; then
    log "Lade ISO herunter..."
    wget -O "$DOWNLOAD_DIR/freelancer_iso.zip" "$FREELANCER_ISO_URL" || err "ISO Download fehlgeschlagen"
  else
    log "ISO ZIP bereits vorhanden"
  fi

  log "Entpacke ISO..."
  unzip -o "$DOWNLOAD_DIR/freelancer_iso.zip" -d . 2>/dev/null || err "Entpacken fehlgeschlagen"
  ISO_FILE=$(find . -maxdepth 2 -type f -name "*.iso" | head -n 1)
  [[ -z "$ISO_FILE" ]] && err "Keine ISO gefunden"
fi

log "Verwende ISO: $ISO_FILE"

### ===== ISO mounten & Setup starten =====

if mountpoint -q "$MOUNT_DIR" 2>/dev/null; then
  fusermount -u "$MOUNT_DIR" 2>/dev/null || umount "$MOUNT_DIR" 2>/dev/null || true
fi

mkdir -p "$MOUNT_DIR"

log "Mounte ISO..."
fuseiso "$ISO_FILE" "$MOUNT_DIR" || err "ISO-Mount fehlgeschlagen"

log "Suche Setup.exe in ISO..."
SETUP_EXE=$(find "$MOUNT_DIR" -maxdepth 2 -type f \( -iname "setup.exe" -o -iname "install.exe" \) | head -n 1)
[[ -z "$SETUP_EXE" ]] && err "Setup.exe nicht in ISO gefunden"

log "Starte Setup (silent) aus ISO..."
timeout 300 wine "$SETUP_EXE" /S /D="C:\Program Files\Microsoft Games\Freelancer" 2>/dev/null || true

sleep 2
log "Freelancer Installation abgeschlossen"

### ===== Starte Downloads parallel =====

log "=== Schritt 2: HD-Mod, Discovery & No-CD Download (parallel) ==="

HDMOD_DL_PID=""
if [[ ! -f "$DOWNLOAD_DIR/hdmod.exe" ]]; then
  log "Starte HD-Mod Download im Hintergrund..."
  wget -O "$DOWNLOAD_DIR/hdmod.exe" "$HD_MOD_URL" &
  HDMOD_DL_PID=$!
fi

DISCOVERY_DL_PID=""
DISCOVERY_INSTALLER="$DOWNLOAD_DIR/discovery_mod.exe"
if [[ ! -f "$DISCOVERY_INSTALLER" ]]; then
  log "Starte Discovery Mod Download im Hintergrund..."
  wget -O "$DISCOVERY_INSTALLER" "$DISCOVERY_MOD_URL" &
  DISCOVERY_DL_PID=$!
fi

NOCD_DL_PID=""
if [[ ! -f "$DOWNLOAD_DIR/freelancer_nocd.zip" ]]; then
  log "Starte No-CD Download im Hintergrund..."
  wget -O "$DOWNLOAD_DIR/freelancer_nocd.zip" "$FREELANCER_NOCD_URL" &
  NOCD_DL_PID=$!
fi

### ===== Warte auf HD-Mod & installiere =====

if [[ -n "$HDMOD_DL_PID" ]]; then
  log "Warte auf HD-Mod Download..."
  wait "$HDMOD_DL_PID" 2>/dev/null || true
fi

if [[ -f "$DOWNLOAD_DIR/hdmod.exe" ]]; then
  log "Installiere HD-Mod..."
  wine "$DOWNLOAD_DIR/hdmod.exe" || true
  log "HD-Mod Installation fertig"
fi

### ===== Warte auf Discovery Download & installiere =====

if [[ -n "$DISCOVERY_DL_PID" ]]; then
  log "Warte auf Discovery Mod Download..."
  wait "$DISCOVERY_DL_PID" 2>/dev/null || true
fi

if [[ -f "$DISCOVERY_INSTALLER" ]]; then
  log "Installiere Discovery Mod..."
  timeout 600 wine "$DISCOVERY_INSTALLER" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- || log "Discovery Installation mit Timeout beendet"
  log "✓ Discovery Mod installiert"
else
  log "Warnung: Discovery Installer nicht gefunden"
fi

### ===== Warte auf No-CD & installiere =====

if [[ -n "$NOCD_DL_PID" ]]; then
  log "Warte auf No-CD Download..."
  wait "$NOCD_DL_PID" 2>/dev/null || true
fi

if [[ -f "$DOWNLOAD_DIR/freelancer_nocd.zip" ]]; then
  log "Entpacke No-CD EXE..."
  mkdir -p nocd_temp
  unzip -o "$DOWNLOAD_DIR/freelancer_nocd.zip" -d nocd_temp 2>/dev/null || true

  NOCD_EXE=$(find nocd_temp -type f -iname "*.exe" | head -n 1)
  if [[ -n "$NOCD_EXE" ]]; then
    INSTALL_PATH="$WINEPREFIX/drive_c/Program Files/Microsoft Games/Freelancer"

    if [[ -d "$INSTALL_PATH/EXE" ]]; then
      log "Kopiere No-CD EXE nach $INSTALL_PATH/EXE/Freelancer.exe"
      cp "$NOCD_EXE" "$INSTALL_PATH/EXE/Freelancer.exe" && log "No-CD EXE installiert" || log "No-CD Kopieren fehlgeschlagen"
    else
      log "Warnung: $INSTALL_PATH/EXE existiert nicht. No-CD konnte nicht installiert werden."
    fi
  else
    log "Warnung: Keine EXE in No-CD ZIP gefunden"
  fi

  rm -rf nocd_temp
fi

### ===== Cleanup (Tempfiles löschen) =====

log "Räume temporäre Dateien auf..."

# Unmount ISO
if mountpoint -q "$MOUNT_DIR" 2>/dev/null; then
  fusermount -u "$MOUNT_DIR" 2>/dev/null || umount "$MOUNT_DIR" 2>/dev/null || true
fi

# Lösche temp Ordner
rm -rf "$MOUNT_DIR" nocd_temp 2>/dev/null || true

# Lösche ZIP nach dem entpacken (ISO bleibt)
rm -f "$DOWNLOAD_DIR/freelancer_iso.zip" 2>/dev/null || true

# Lösche alte temp-Dateien aus früheren Läufen
rm -rf mount mount_temp freelancer_nocd_tmp 2>/dev/null || true

log "Cleanup abgeschlossen"
log "✓ Installation abgeschlossen!"
log "✓ Downloads sind in: $DOWNLOAD_DIR/"
log "✓ Spiel starten mit: ./play_freelancer.sh"

