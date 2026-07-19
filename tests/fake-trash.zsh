#!/bin/zsh

emulate -L zsh

typeset fake_mode="${RM_AIRBAG_FAKE_MODE:-success}"
typeset allowed_root="${RM_AIRBAG_TEST_ROOT:-}"
typeset fake_store="${RM_AIRBAG_FAKE_TRASH:-}"
typeset target absolute_target destination counter=0

[[ -n "$allowed_root" && -n "$fake_store" ]] || {
  print -u2 -r -- "fake-trash: missing test environment"
  exit 64
}

case "$fake_mode" in
  fail)
    print -u2 -r -- "fake-trash: simulated failure"
    exit 1
    ;;
  batch-fallback)
    if (( $# > 1 )); then
      print -u2 -r -- "fake-trash: simulated batch failure"
    fi
    exit 1
    ;;
  success) ;;
  *) print -u2 -r -- "fake-trash: unknown mode: $fake_mode"; exit 64 ;;
esac

/bin/mkdir -p "$fake_store" || exit 1
for target in "$@"; do
  absolute_target="${target:a}"
  if [[ "$absolute_target" != "$allowed_root"/* ]]; then
    print -u2 -r -- "fake-trash: refused path outside test root: $target"
    exit 65
  fi
  [[ -e "$target" || -L "$target" ]] || {
    print -u2 -r -- "fake-trash: missing operand: $target"
    exit 1
  }
  (( counter++ ))
  destination="$fake_store/${target:t}.$counter"
  /bin/mv -- "$target" "$destination" || exit 1
done

