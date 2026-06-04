# Sourceable helper for email tasks.
# Sets: AGENT, CONFIG_FILE
# When sourced with NEED_IMAP=1, also sets: PASS
#
# Usage: source "$MISE_CONFIG_ROOT/lib/email.sh"

export RUST_LOG=error
HIMALAYA_BIN="${HIMALAYA:-himalaya}"

# Determine current agent from environment or git config
if [ -n "${GIT_AUTHOR_EMAIL:-}" ]; then
  AGENT=$(echo "$GIT_AUTHOR_EMAIL" | sed 's/@ricon\.family$//')
elif git config user.email 2>/dev/null | grep -q '@ricon.family'; then
  AGENT=$(git config user.email | sed 's/@ricon\.family$//')
else
  echo "No agent identity detected. Run: eval \$(shimmer as <agent>)"
  return 1 2>/dev/null || exit 1
fi

CONFIG_FILE="${HIMALAYA_CONFIG:-${HOME}/.config/himalaya/config.toml}"
if [ ! -f "$CONFIG_FILE" ] || ! grep -q "accounts.$AGENT" "$CONFIG_FILE" 2>/dev/null; then
  echo "Email not configured for $AGENT. Run: emails setup $AGENT"
  return 1 2>/dev/null || exit 1
fi

# IMAP password — only extracted when caller needs direct IMAP access
if [ "${NEED_IMAP:-0}" = "1" ]; then
  PASS=$(grep -A30 "accounts.$AGENT" "$CONFIG_FILE" | grep 'auth.raw' | head -1 | sed 's/.*= *"//' | sed 's/"$//')
  if [ -z "$PASS" ]; then
    echo "Could not read email password from config"
    return 1 2>/dev/null || exit 1
  fi
fi

# Name the detached PGP/MIME signature part so recipients (e.g. Gmail) see
# "signature.asc" instead of "noname". himalaya/mml emit the signature part as a
# bare `Content-Type: application/pgp-signature` with no name/disposition/description
# (pimalaya/core mml/src/message/body/compiler/mod.rs), so we inject the standard
# headers here. This is safe: a PGP/MIME signature covers only the canonicalised
# clear part, never the signature part's own MIME headers, so the signature stays
# valid. Reads a raw .eml on stdin, writes the rewritten message to stdout;
# CRLF line endings are preserved.
inject_signature_name() {
  awk '
    !done && tolower($0) ~ /^content-type:[[:space:]]*application\/pgp-signature[[:space:]]*\r?$/ {
      cr = ""
      if (sub(/\r$/, "")) cr = "\r"
      print $0 "; name=\"signature.asc\"" cr
      print "Content-Disposition: attachment; filename=\"signature.asc\"" cr
      print "Content-Description: OpenPGP digital signature" cr
      done = 1
      next
    }
    { print }
  '
}
