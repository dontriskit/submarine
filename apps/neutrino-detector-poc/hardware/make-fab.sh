#!/usr/bin/env bash
# make-fab.sh — Generate fab-ready outputs for the neutrino-detector-poc PCB set.
#
# Usage:
#   ./make-fab.sh                # all 5 boards
#   ./make-fab.sh 01             # only board 01 (matches dir prefix)
#   ./make-fab.sh 01 02          # two boards
#
# Requires: KiCad ≥ 9.0.9 (provides kicad-cli) and zip.
#
# Outputs per board:
#   NN-board/fab/*.gbr           ← Gerbers (one per layer, RS-274X)
#   NN-board/fab/*.drl           ← Excellon drill file
#   NN-board/fab/*-drl_map.pdf   ← drill map for human eyeball
#   NN-board/fab/*-cpl.csv       ← pick-and-place (only if board has footprints)
#   NN-board/<base>-fab.zip      ← upload-ready bundle for JLCPCB / OSHPark / Aisler

set -euo pipefail

# ---------- preflight ----------
if ! command -v kicad-cli >/dev/null 2>&1; then
  cat >&2 <<EOF
Error: kicad-cli not found on PATH.

Install KiCad ≥ 9.0.9 first. On Ubuntu / Debian-derivative:
  sudo add-apt-repository ppa:kicad/kicad-9.0-releases
  sudo apt update
  sudo apt install kicad

Then re-run this script.
EOF
  exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
  echo "Error: zip not found. apt install zip" >&2
  exit 1
fi

KICAD_VER="$(kicad-cli --version 2>&1 | head -1 || echo unknown)"
echo "Using $KICAD_VER"

# ---------- board table ----------
# dir : base-filename : layer-count
BOARDS=(
  "01-sipm-frontend:sipm-frontend:4"
  "02-mainboard:mainboard:4"
  "03-power:power:4"
  "04-surface-aggregator:surface-aggregator:4"
  "05-led-pulser:led-pulser:2"
)

# ---------- layer presets ----------
LAYERS_2L="F.Cu,B.Cu,F.Paste,B.Paste,F.Silkscreen,B.Silkscreen,F.Mask,B.Mask,Edge.Cuts"
LAYERS_4L="F.Cu,In1.Cu,In2.Cu,B.Cu,F.Paste,B.Paste,F.Silkscreen,B.Silkscreen,F.Mask,B.Mask,Edge.Cuts"

# ---------- filter ----------
FILTERS=("$@")
match_filter() {
  local dir="$1"
  if [[ ${#FILTERS[@]} -eq 0 ]]; then return 0; fi
  for f in "${FILTERS[@]}"; do
    [[ "$dir" == *"$f"* ]] && return 0
  done
  return 1
}

# ---------- export loop ----------
HARDWARE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HARDWARE_DIR"

for entry in "${BOARDS[@]}"; do
  IFS=":" read -r dir base layers <<< "$entry"
  if ! match_filter "$dir"; then continue; fi

  pcb="$dir/$base.kicad_pcb"
  fab="$dir/fab"
  zipfile="$dir/${base}-fab.zip"

  if [[ ! -f "$pcb" ]]; then
    echo "  skip  $dir — no $base.kicad_pcb yet"
    continue
  fi

  echo ""
  echo "▶ $dir  ($layers-layer)"
  rm -rf "$fab"
  mkdir -p "$fab"

  case "$layers" in
    "2") layerset="$LAYERS_2L" ;;
    *)   layerset="$LAYERS_4L" ;;
  esac

  echo "  · gerbers"
  kicad-cli pcb export gerbers \
    --output "$fab/" \
    --layers "$layerset" \
    --no-x2 \
    --use-drill-file-origin \
    "$pcb" 2>&1 | sed 's/^/      /'

  echo "  · drill"
  kicad-cli pcb export drill \
    --output "$fab/" \
    --format excellon \
    --excellon-units mm \
    --excellon-zeros-format suppressleading \
    --excellon-oval-format alternate \
    --drill-origin absolute \
    --generate-map \
    --map-format pdf \
    "$pcb" 2>&1 | sed 's/^/      /'

  echo "  · pick-and-place"
  if ! kicad-cli pcb export pos \
        --output "$fab/${base}-cpl.csv" \
        --format csv \
        --units mm \
        --side both \
        --use-drill-file-origin \
        "$pcb" 2>&1 | sed 's/^/      /'; then
    echo "      (no footprints — pos file empty; that's expected for skeletons)"
  fi

  echo "  · zip"
  rm -f "$zipfile"
  (cd "$fab" && zip -qj "../$(basename "$zipfile")" \
     *.gbr *.drl *.csv 2>/dev/null || true)

  echo "  ✓ $fab/  →  $zipfile"
done

echo ""
echo "Done. Upload each *-fab.zip to your fab house."
echo "JLCPCB: https://jlcpcb.com/quote  (their viewer accepts the zip directly)"
