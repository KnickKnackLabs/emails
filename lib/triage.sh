#!/usr/bin/env bash
# triage.sh — email classification logic
#
# Classifies inbox messages into categories based on subject, bodyPreview,
# and sender. Used by the triage and clean tasks.
#
# Input: JSON from Graph API inbox endpoint (full response with .value array)
# Output: JSON with categorized message IDs and metadata

# Classify a single message JSON object into a category.
# Returns one of: actionable, noise, bulk, other
classify_message() {
  local msg="$1"
  echo "$msg" | jq -r '
    # Extract fields
    .from.emailAddress.name as $sender_name |
    .from.emailAddress.address as $sender_addr |
    .bodyPreview as $body |
    .subject as $subject |

    # Bot senders (always noise)
    if ($sender_name | test("\\[bot\\]")) then "noise"

    # GitHub review comments and change requests (actionable)
    elif ($body | test("commented on this pull request")) then "actionable"
    elif ($body | test("requested changes on this pull request")) then "actionable"
    elif ($body | test("approved this pull request")) then "actionable"

    # GitHub merge notifications (noise)
    elif ($body | test("^Merged #")) then "noise"

    # GitHub push notifications (noise)
    elif ($body | test("pushed [0-9]+ commit")) then "noise"

    # GitHub review request pings (noise)
    elif ($body | test("requested your review on")) then "noise"

    # Bulk/newsletter senders
    elif ($sender_name | test("^Global Tech"; "i")) then "bulk"
    elif ($sender_name | test("^Team Productivity"; "i")) then "bulk"
    elif ($sender_addr | test("globaltech@|teamproductivity@|donotreply@|no-reply@"; "i")) then "bulk"

    # Everything else
    else "other"
    end
  '
}

# Classify all messages in an inbox response.
# Input: full Graph API response JSON (with .value array)
# Output: JSON object with categorized arrays:
#   { actionable: [...], noise: [...], bulk: [...], other: [...] }
# Each array element has: { id, num, subject, from, category }
classify_inbox() {
  local response="$1"
  echo "$response" | jq '
    .value | to_entries | map(
      .key as $idx |
      .value |
      .from.emailAddress.name as $sender_name |
      .from.emailAddress.address as $sender_addr |
      .bodyPreview as $body |
      .subject as $subject |

      # Classify
      (
        if ($sender_name | test("\\[bot\\]")) then "noise"
        elif ($body | test("commented on this pull request")) then "actionable"
        elif ($body | test("requested changes on this pull request")) then "actionable"
        elif ($body | test("approved this pull request")) then "actionable"
        elif ($body | test("^Merged #")) then "noise"
        elif ($body | test("pushed [0-9]+ commit")) then "noise"
        elif ($body | test("requested your review on")) then "noise"
        elif ($sender_name | test("^Global Tech"; "i")) then "bulk"
        elif ($sender_name | test("^Team Productivity"; "i")) then "bulk"
        elif ($sender_addr | test("globaltech@|teamproductivity@|donotreply@|no-reply@"; "i")) then "bulk"
        else "other"
        end
      ) as $category |

      {
        id: .id,
        num: ($idx + 1),
        subject: $subject,
        from: $sender_name,
        category: $category
      }
    ) | group_by(.category) | map({ (.[0].category): . }) | add //
    { actionable: [], noise: [], bulk: [], other: [] } |
    # Ensure all keys exist
    { actionable: (.actionable // []), noise: (.noise // []), bulk: (.bulk // []), other: (.other // []) }
  '
}
