#!/bin/zsh

emulate -L zsh
set -e

typeset script_dir="${0:A:h}"
typeset project_root="${script_dir:h}"
typeset config_home="${RM_AIRBAG_HOME:-$HOME}"
typeset install_dir="$config_home/.local/bin"
typeset install_path="$install_dir/rm-airbag"
typeset backup_dir="$config_home/.local/share/rm-airbag/backups"
typeset enable_option="${1:-}"

case "$enable_option" in
  ""|--shim-only) ;;
  *) print -u2 -r -- "install.sh: unknown option: $enable_option"; exit 2 ;;
esac

[[ -x "$project_root/bin/rm-airbag" ]] || {
  print -u2 -r -- "install.sh: missing executable: $project_root/bin/rm-airbag"
  exit 1
}

/bin/mkdir -p "$install_dir" "$backup_dir"
if [[ -e "$install_path" ]] && ! /usr/bin/cmp -s "$project_root/bin/rm-airbag" "$install_path"; then
  /bin/cp -p "$install_path" "$backup_dir/rm-airbag-before-install-$(/bin/date '+%Y%m%d-%H%M%S')"
fi

/usr/bin/install -m 0755 "$project_root/bin/rm-airbag" "$install_path"
if [[ "$enable_option" == "--shim-only" ]]; then
  "$install_path" enable --shim-only
else
  "$install_path" enable
fi

print -r -- "Installed rm-airbag $($install_path version) at $install_path"

