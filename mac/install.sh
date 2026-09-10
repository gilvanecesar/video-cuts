#!/bin/sh
# Video Cuts — everything the Mac side needs, in one command.
#
#   curl -fsSL https://raw.githubusercontent.com/gilvanecesar/video-cuts/main/mac/install.sh | sh
#
# Idempotent: run it twice and it does nothing the second time. It never
# touches anything outside ~/.dailies and ~/Movies/Dailies except for two
# Homebrew formulae, and it says so before installing them.
set -e

HOME_DIR="${DAILIES_HOME:-$HOME/.dailies}"
INTAKE="${DAILIES_INTAKE:-$HOME/Movies/Dailies}"
RAW="https://raw.githubusercontent.com/gilvanecesar/video-cuts/main"
say() { printf '\033[1m%s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

say "Video Cuts — setting up the Mac side"
mkdir -p "$HOME_DIR/bin" "$HOME_DIR/models" "$HOME_DIR/assets" "$INTAKE"

# --- tools -----------------------------------------------------------------
# Plain `ffmpeg` from Homebrew ships without libass, so `subtitles`, `ass` and
# `drawtext` do not exist in it and every graphic silently fails to draw.
# ffmpeg-full has them; it installs keg-only, which is fine — plowcut looks for
# a capable binary rather than trusting PATH.
if [ ! -x /opt/homebrew/opt/ffmpeg-full/bin/ffmpeg ] && [ ! -x /usr/local/opt/ffmpeg-full/bin/ffmpeg ]; then
  have brew || { echo "Homebrew is needed: https://brew.sh"; exit 1; }
  say "  installing ffmpeg-full (this is the long one)"
  brew install ffmpeg-full
fi
have whisper-cli || { say "  installing whisper-cpp"; brew install whisper-cpp; }

# --- model -----------------------------------------------------------------
# small, not base: base garbles about a third of a recording, and every topic
# and hook the agent picks rests on this text. Multilingual, not .en — an .en
# model does not do worse on other languages, it translates them.
MODEL="$HOME_DIR/models/ggml-small.bin"
if [ ! -f "$MODEL" ]; then
  say "  downloading the transcription model (465MB, once)"
  curl -fL --progress-bar -o "$MODEL" \
    "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin"
fi

# --- fonts -----------------------------------------------------------------
# Icons are a font, not a folder of images: libass renders "smartphone" as the
# glyph, so there is nothing to rasterise and nothing to keep in sync.
fetch() { [ -f "$HOME_DIR/assets/$1" ] || curl -fsL -o "$HOME_DIR/assets/$1" "$2"; }
say "  fetching fonts"
fetch icons.ttf   "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"
fetch Anton.ttf   "https://github.com/google/fonts/raw/main/ofl/anton/Anton-Regular.ttf"
fetch Inter.ttf   "https://github.com/google/fonts/raw/main/ofl/inter/Inter%5Bopsz%2Cwght%5D.ttf"

# --- the Mac side ----------------------------------------------------------
# A canonical launcher the agent can always find. The sandbox does not expand
# ~ and does not carry ~/.dailies/bin on PATH, so the agent must use one fixed
# absolute path; we also drop a copy where common PATHs look, best-effort.
say "  installing plowcut"
if [ -f "$(dirname "$0")/plowcut" ]; then
  install -m 0755 "$(dirname "$0")/plowcut" "$HOME_DIR/bin/plowcut"
  SRC_DIR="$(dirname "$0")"
else
  curl -fsL -o "$HOME_DIR/bin/plowcut" "$RAW/mac/plowcut" && chmod 0755 "$HOME_DIR/bin/plowcut"
  SRC_DIR=""
fi

# Face framing uses the Vision framework that ships with macOS: no model to
# download and no opencv. It needs a compiler, which most Macs have; without
# one the agent falls back to a centre crop and says so rather than pretending.
if have swiftc; then
  say "  building facefind (macOS Vision — no model download)"
  SWIFT="$SRC_DIR/facefind.swift"
  [ -f "$SWIFT" ] || { SWIFT="$HOME_DIR/facefind.swift"; curl -fsL -o "$SWIFT" "$RAW/mac/facefind.swift"; }
  swiftc -O -o "$HOME_DIR/bin/facefind" "$SWIFT" 2>/dev/null || \
    echo "  (facefind did not build — framing will centre-crop)"
else
  echo "  (no swiftc — framing will centre-crop; install Xcode command line tools for face framing)"
fi

say ""
"$HOME_DIR/bin/plowcut" status
say ""
say ""
say "The agent runs plowcut by this exact path — it is printed here so the"
say "first message to your agent can hand it over:"
say "  $HOME_DIR/bin/plowcut"
say ""
say "Drop a recording in $INTAKE and text your agent."
