setup_suite() {
  export REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  eval "$(cd "$REPO_DIR" && mise env)"
  # Bats 1.13 invokes internal helpers by name after setup_suite runs.
  # Keep its libexec directory visible if tool-env setup rewrites PATH.
  if [ -n "${BATS_LIBEXEC:-}" ]; then
    export PATH="$BATS_LIBEXEC:$PATH"
  fi
}
