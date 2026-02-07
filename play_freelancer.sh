#!/usr/bin/env bash
set -euo pipefail

### ===== Umgebungserkennung =====

detect_system() {
  if [[ -f /etc/steamos-os-release ]]; then
    echo "steamos"
  elif [[ -f /etc/os-release ]] && grep -q "CachyOS" /etc/os-release; then
    echo "cachyos"
  elif [[ -f /etc/os-release ]] && grep -q "Arch" /etc/os-release; then
    echo "arch"
  elif [[ -f /etc/os-release ]] && grep -q "Ubuntu\|Debian" /etc/os-release; then
    echo "debian"
  else
    echo "unknown"
  fi
}

SYSTEM_TYPE=$(detect_system)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export WINEPREFIX="$SCRIPT_DIR/wine-freelancer"
export WINEARCH="win64"
export WINEDEBUG=-all

echo "==================================="
echo "Freelancer Launcher"
echo "System: $SYSTEM_TYPE"
echo "==================================="
echo ""

# Check if Freelancer is installed
HD_EDITION_EXE="$WINEPREFIX/drive_c/Games/Freelancer HD Edition/EXE/Freelancer.exe"
DISCOVERY_EXE=""

# Find Discovery installation
for DISCOVERY_PATH in \
  "$WINEPREFIX/drive_c/users/$USER/AppData/Local/Discovery Freelancer 5.3.2/EXE/Freelancer.exe" \
  "$WINEPREFIX/drive_c/users/*/AppData/Local/Discovery Freelancer 5.3.2/EXE/Freelancer.exe" \
  "$WINEPREFIX/drive_c/Program Files/Discovery Freelancer/EXE/Freelancer.exe" \
  "$WINEPREFIX/drive_c/Discovery/EXE/Freelancer.exe" \
  "$WINEPREFIX/drive_c/Games/Discovery Freelancer/EXE/Freelancer.exe" \
  "$WINEPREFIX/drive_c/Program Files/Microsoft Games/Freelancer Discovery/EXE/Freelancer.exe"; do
  if [[ -f "$DISCOVERY_PATH" ]]; then
    DISCOVERY_EXE="$DISCOVERY_PATH"
    break
  fi
done

if [[ ! -f "$HD_EDITION_EXE" ]] && [[ -z "$DISCOVERY_EXE" ]]; then
  echo "[!] Freelancer ist noch nicht installiert!"
  echo "[*] Starte Installation..."
  echo ""

  # Run the installer script
  "$SCRIPT_DIR/install_freelancer.sh"

  echo ""
  echo "[*] Installation abgeschlossen!"
  echo ""

  # Re-check for installed versions
  for DISCOVERY_PATH in \
    "$WINEPREFIX/drive_c/users/$USER/AppData/Local/Discovery Freelancer 5.3.2/EXE/Freelancer.exe" \
    "$WINEPREFIX/drive_c/users/*/AppData/Local/Discovery Freelancer 5.3.2/EXE/Freelancer.exe" \
    "$WINEPREFIX/drive_c/Program Files/Discovery Freelancer/EXE/Freelancer.exe" \
    "$WINEPREFIX/drive_c/Discovery/EXE/Freelancer.exe" \
    "$WINEPREFIX/drive_c/Games/Discovery Freelancer/EXE/Freelancer.exe" \
    "$WINEPREFIX/drive_c/Program Files/Microsoft Games/Freelancer Discovery/EXE/Freelancer.exe"; do
    if [[ -f "$DISCOVERY_PATH" ]]; then
      DISCOVERY_EXE="$DISCOVERY_PATH"
      break
    fi
  done
fi

# Game mode selection
MODE=""
if [[ -f "$HD_EDITION_EXE" ]] && [[ -n "$DISCOVERY_EXE" ]]; then
  echo "=== Freelancer Launcher ==="
  echo "Welchen Modus möchtest du spielen?"
  echo "  [1] Freelancer HD Edition (Vanilla)"
  echo "  [2] Discovery Mod"
  echo ""
  read -p "Auswahl [1-2]: " CHOICE

  case "$CHOICE" in
    1)
      MODE="hd"
      ;;
    2)
      MODE="discovery"
      ;;
    *)
      echo "[!] Ungültige Auswahl, starte HD Edition"
      MODE="hd"
      ;;
  esac
elif [[ -f "$HD_EDITION_EXE" ]]; then
  MODE="hd"
elif [[ -n "$DISCOVERY_EXE" ]]; then
  MODE="discovery"
else
  echo "[!] Keine spielbare Version gefunden!"
  exit 1
fi

# Launch selected mode
if [[ "$MODE" == "hd" ]]; then
  echo "[*] Starte Freelancer HD Edition"
  cd "$WINEPREFIX/drive_c/Games/Freelancer HD Edition"
  env WINEPREFIX="$WINEPREFIX" wine 'C:\Games\Freelancer HD Edition\EXE\Freelancer.exe'
elif [[ "$MODE" == "discovery" ]]; then
  echo "[*] Starte Discovery Mod"
  # Discovery verwendet DSLauncher.exe im Hauptverzeichnis
  DISCOVERY_BASE_DIR=$(dirname "$(dirname "$DISCOVERY_EXE")")
  DSLAUNCHER="$DISCOVERY_BASE_DIR/DSLauncher.exe"

  if [[ -f "$DSLAUNCHER" ]]; then
    cd "$DISCOVERY_BASE_DIR"
    env WINEPREFIX="$WINEPREFIX" wine "$DSLAUNCHER"
  else
    # Fallback auf direkte Freelancer.exe
    DISCOVERY_DIR=$(dirname "$DISCOVERY_EXE")
    cd "$(dirname "$DISCOVERY_DIR")"
    env WINEPREFIX="$WINEPREFIX" wine "$DISCOVERY_EXE"
  fi
fi


