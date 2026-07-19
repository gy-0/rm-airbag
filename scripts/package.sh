#!/bin/zsh

emulate -L zsh
set -e

typeset script_dir="${0:A:h}"
typeset project_root="${script_dir:h}"
typeset project_parent="${project_root:h}"
typeset project_name="${project_root:t}"
typeset version="$($project_root/bin/rm-airbag version)"
typeset dist_dir="$project_root/dist"
typeset archive="$dist_dir/rm-airbag-$version.tar.gz"

/bin/mkdir -p "$dist_dir"
/usr/bin/tar \
  --exclude "$project_name/.git" \
  --exclude "$project_name/dist" \
  -czf "$archive" \
  -C "$project_parent" \
  "$project_name"

(cd "$dist_dir" && /usr/bin/shasum -a 256 "${archive:t}" >| "${archive:t}.sha256")
print -r -- "$archive"
print -r -- "$archive.sha256"

