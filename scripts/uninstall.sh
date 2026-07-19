#!/bin/zsh

emulate -L zsh
set -e

typeset config_home="${RM_AIRBAG_HOME:-$HOME}"
typeset install_path="$config_home/.local/bin/rm-airbag"

if [[ -x "$install_path" ]]; then
  "$install_path" disable
  /bin/rm -f -- "$install_path"
else
  print -r -- "rm-airbag executable is not installed at $install_path"
fi

print -r -- "rm-airbag uninstalled"
print -r -- "Configuration backups under $config_home/.local/share/rm-airbag/backups were preserved."

