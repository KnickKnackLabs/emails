#!/usr/bin/env bats
# Tests for emails setup task

bats_require_minimum_version 1.5.0
load helpers

setup() {
  setup_mock_himalaya
  export HIMALAYA_CONFIG="$BATS_TEST_TMPDIR/himalaya/config.toml"
  export EMAIL_PASSWORD="fake-password"
}

@test "setup: configures account-specific GPG signing key" {
  run emails setup c0da

  [ "$status" -eq 0 ]
  [[ "$output" == *"Email configured for c0da@ricon.family"* ]]
  grep -qF 'pgp.sign-cmd = "gpg --local-user c0da@ricon.family --sign --quiet --armor"' "$HIMALAYA_CONFIG"
}

@test "setup: appended account uses its own signing key" {
  mkdir -p "$(dirname "$HIMALAYA_CONFIG")"
  cat > "$HIMALAYA_CONFIG" <<'EOF'
[accounts.zeke]
default = true
email = "zeke@ricon.family"
pgp.sign-cmd = "gpg --local-user zeke@ricon.family --sign --quiet --armor"
EOF

  run emails setup k7r2

  [ "$status" -eq 0 ]
  grep -qF '[accounts.k7r2]' "$HIMALAYA_CONFIG"
  grep -qF 'pgp.sign-cmd = "gpg --local-user k7r2@ricon.family --sign --quiet --armor"' "$HIMALAYA_CONFIG"
  grep -qF 'default = false' "$HIMALAYA_CONFIG"
}
