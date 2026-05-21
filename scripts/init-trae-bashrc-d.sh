#!/usr/bin/env bash
set -euo pipefail

BASHRC_SNIPPET='for f in ~/.bashrc.d/*.sh; do [ -r "$f" ] && source "$f"; done'

if [ ! -f ~/.bashrc ]; then
  echo "=> [Container Error] Core configuration file ~/.bashrc does not exist! Image or Initialization failed."
  exit 1
fi

if ! grep -qF "$BASHRC_SNIPPET" ~/.bashrc; then
  echo "$BASHRC_SNIPPET" >> ~/.bashrc
  echo "=> [Init] Added ~/.bashrc.d auto-loading to ~/.bashrc"
else
  echo "=> [Init] ~/.bashrc.d auto-loading already present"
fi

mkdir -p ~/.bashrc.d
