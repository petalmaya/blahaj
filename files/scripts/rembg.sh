#!/usr/bin/env bash
# rembg powers kurukurubar's lock-screen "Fg Layer Extraction" effect.
# It's a Python package, not an RPM - pipx installs it isolated from the
# system Python, same approach flutterquick's own README recommends.
set -oue pipefail

pipx install --global rembg
