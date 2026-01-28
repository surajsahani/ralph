#!/bin/bash
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Functions
log() {
  echo "Ralph: $1" >&2
}

die() {
  echo "❌ Error: $1" >&2
  exit 1
}

# Setup paths
STATE_DIR=".gemini/ralph"
STATE_FILE="$STATE_DIR/state.json"

# Read hook input from stdin
INPUT=$(cat)
LAST_MESSAGE=$(echo "$INPUT" | jq -r '.prompt_response')

# Check if loop is active
if [[ ! -f "$STATE_FILE" ]]; then
    echo '{"decision": "allow"}'
    exit 0
fi

ACTIVE=$(jq -r '.active' "$STATE_FILE")
if [[ "$ACTIVE" != "true" ]]; then
    echo '{"decision": "allow"}'
    exit 0
fi

# Increment iteration
TMP_STATE=$(mktemp)
jq '.current_iteration += 1' "$STATE_FILE" > "$TMP_STATE" || die "Failed to increment iteration"
mv "$TMP_STATE" "$STATE_FILE"

# Log progress (persona)
log "I'm doing a circle! Iteration $(jq -r '.current_iteration' "$STATE_FILE") is done."

# Maintain the loop by forcing a retry with the original prompt
ORIGINAL_PROMPT=$(jq -r '.original_prompt' "$STATE_FILE")

cat <<EOF
{
  "decision": "deny",
  "reason": "$ORIGINAL_PROMPT",
  "systemMessage": "🔄 Ralph is starting the next iteration..."
}
EOF

exit 0
