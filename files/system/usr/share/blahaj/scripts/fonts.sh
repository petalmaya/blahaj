#!/usr/bin/env bash
# Fonts kurukurubar (quickshell config) expects that aren't packaged in
# Fedora: Material Symbols, a nerd-fonted Noto Sans Mono, and
# librebarcode. Pulled straight into /usr/share/fonts at build time so
# every user gets them, no per-user fc-cache dance needed.
set -oue pipefail

FONT_DIR=/usr/share/fonts/blahaj
mkdir -p "${FONT_DIR}"

echo "Fetching Material Symbols (variable, rounded)..."
curl -fL -o "${FONT_DIR}/MaterialSymbolsRounded.ttf" \
  "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"

# NOTE: nerd-fonts' "Noto.zip" release bundle only ships
# NotoMonoNerdFontPropo (not a NotoSansMono/Propo variant) - that's the
# closest match to the "NotoSansM Nerd Font Propo" family flutterquick's
# README names. Verify the glyph coverage looks right once built; swap
# the find pattern below if a truer match shows up in a future release.
echo "Fetching NotoSansM Nerd Font Propo..."
TMP="$(mktemp -d)"
curl -fL -o "${TMP}/Noto.zip" \
  "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Noto.zip"
unzip -oq "${TMP}/Noto.zip" -d "${TMP}/Noto"
find "${TMP}/Noto" -iname '*Mono*Propo*.ttf' -exec cp {} "${FONT_DIR}/" \;
rm -rf "${TMP}"

echo "Fetching Libre Barcode 39 Text..."
curl -fL -o "${FONT_DIR}/LibreBarcode39Text.ttf" \
  "https://github.com/google/fonts/raw/main/ofl/librebarcode39text/LibreBarcode39Text-Regular.ttf"

fc-cache -f "${FONT_DIR}"
