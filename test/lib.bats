#!/usr/bin/env bats
# Tests for lib/email.sh — agent identity detection and config validation

bats_require_minimum_version 1.5.0

setup() {
  # Use HIMALAYA_CONFIG to isolate from real config
  export HIMALAYA_CONFIG="$BATS_TEST_TMPDIR/himalaya/config.toml"
  mkdir -p "$(dirname "$HIMALAYA_CONFIG")"
}

# ============================================================================
# Identity detection
# ============================================================================

@test "lib: detects agent from GIT_AUTHOR_EMAIL" {
  export GIT_AUTHOR_EMAIL="myagent@ricon.family"
  cat > "$HIMALAYA_CONFIG" <<EOF
[accounts.myagent]
default = true
EOF

  # Source the lib and check AGENT is set
  run bash -c 'source "$REPO_DIR/lib/email.sh" && echo "$AGENT"'
  [ "$status" -eq 0 ]
  [ "$output" = "myagent" ]
}

@test "lib: fails without identity" {
  unset GIT_AUTHOR_EMAIL
  # Ensure git config doesn't have a ricon email
  export GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/gitconfig"
  echo "" > "$GIT_CONFIG_GLOBAL"

  GIT_CONFIG_COUNT=0 run bash -c 'source "$REPO_DIR/lib/email.sh"'
  [ "$status" -ne 0 ]
  [[ "$output" == *"No agent identity"* ]]
}

@test "lib: fails without himalaya config" {
  export GIT_AUTHOR_EMAIL="myagent@ricon.family"
  rm -f "$HIMALAYA_CONFIG"

  GIT_CONFIG_COUNT=0 run bash -c 'source "$REPO_DIR/lib/email.sh"'
  [ "$status" -ne 0 ]
  [[ "$output" == *"not configured"* ]]
}

@test "lib: fails when agent account missing from config" {
  export GIT_AUTHOR_EMAIL="myagent@ricon.family"
  # Config exists but has a different account
  cat > "$HIMALAYA_CONFIG" <<EOF
[accounts.otheragent]
default = true
EOF

  GIT_CONFIG_COUNT=0 run bash -c 'source "$REPO_DIR/lib/email.sh"'
  [ "$status" -ne 0 ]
  [[ "$output" == *"not configured"* ]]
}

# ============================================================================
# IMAP password extraction
# ============================================================================

@test "lib: extracts IMAP password when NEED_IMAP=1" {
  export GIT_AUTHOR_EMAIL="myagent@ricon.family"
  cat > "$HIMALAYA_CONFIG" <<EOF
[accounts.myagent]
default = true
backend.auth.type = "password"
backend.auth.raw = "s3cret-pass"
EOF

  run bash -c 'NEED_IMAP=1 source "$REPO_DIR/lib/email.sh" && echo "$PASS"'
  [ "$status" -eq 0 ]
  [ "$output" = "s3cret-pass" ]
}

@test "lib: PASS is empty when NEED_IMAP not set" {
  export GIT_AUTHOR_EMAIL="myagent@ricon.family"
  cat > "$HIMALAYA_CONFIG" <<EOF
[accounts.myagent]
default = true
backend.auth.type = "password"
backend.auth.raw = "s3cret-pass"
EOF

  run bash -c 'source "$REPO_DIR/lib/email.sh" && echo "PASS=${PASS:-empty}"'
  [ "$status" -eq 0 ]
  [ "$output" = "PASS=empty" ]
}

# ============================================================================
# inject_signature_name — name the detached PGP/MIME signature part
# ============================================================================

# Provide a valid identity + config so sourcing lib/email.sh succeeds.
_lib_identity() {
  export GIT_AUTHOR_EMAIL="myagent@ricon.family"
  cat > "$HIMALAYA_CONFIG" <<EOF
[accounts.myagent]
default = true
EOF
}

# A himalaya-style multipart/signed message (CRLF) with an unnamed signature part.
_signed_fixture() {
  printf 'Content-Type: multipart/signed; boundary="b"; protocol="application/pgp-signature"; micalg="pgp-sha256"\r\n\r\n--b\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nclear body text\r\n--b\r\nContent-Type: application/pgp-signature\r\nContent-Transfer-Encoding: 7bit\r\n\r\n-----BEGIN PGP SIGNATURE-----\r\n\r\nMOCKSIG==\r\n-----END PGP SIGNATURE-----\r\n--b--\r\n' > "$1"
}

@test "inject_signature_name: adds name, disposition and description headers" {
  _lib_identity
  local fixture="$BATS_TEST_TMPDIR/sig.eml"
  _signed_fixture "$fixture"

  run bash -c "source '$REPO_DIR/lib/email.sh' && inject_signature_name < '$fixture'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'Content-Type: application/pgp-signature; name="signature.asc"'* ]]
  [[ "$output" == *'Content-Disposition: attachment; filename="signature.asc"'* ]]
  [[ "$output" == *'Content-Description: OpenPGP digital signature'* ]]
}

@test "inject_signature_name: leaves clear part and signature body unchanged" {
  _lib_identity
  local fixture="$BATS_TEST_TMPDIR/sig.eml"
  _signed_fixture "$fixture"

  run bash -c "source '$REPO_DIR/lib/email.sh' && inject_signature_name < '$fixture'"
  [[ "$output" == *"clear body text"* ]]
  [[ "$output" == *"-----BEGIN PGP SIGNATURE-----"* ]]
  [[ "$output" == *"MOCKSIG=="* ]]
  # The clear part's own Content-Type must not be touched.
  [[ "$output" == *"Content-Type: text/plain; charset=utf-8"* ]]
  [[ "$output" != *'text/plain; charset=utf-8; name="signature.asc"'* ]]
}

@test "inject_signature_name: rewrites the signature part exactly once" {
  _lib_identity
  local fixture="$BATS_TEST_TMPDIR/sig.eml"
  _signed_fixture "$fixture"

  local count
  count=$(bash -c "source '$REPO_DIR/lib/email.sh' && inject_signature_name < '$fixture'" \
    | grep -c 'pgp-signature; name="signature.asc"')
  [ "$count" -eq 1 ]
}

@test "inject_signature_name: preserves CRLF and adds two CRLF-terminated headers" {
  _lib_identity
  local fixture="$BATS_TEST_TMPDIR/sig.eml"
  _signed_fixture "$fixture"

  local in_cr out_cr
  in_cr=$(tr -cd '\r' < "$fixture" | wc -c)
  out_cr=$(bash -c "source '$REPO_DIR/lib/email.sh' && inject_signature_name < '$fixture'" \
    | tr -cd '\r' | wc -c)
  # One CR for each of the two added header lines (name param is on the existing line).
  [ "$out_cr" -eq "$((in_cr + 2))" ]
}
