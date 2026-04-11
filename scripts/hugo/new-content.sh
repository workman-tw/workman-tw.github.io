#!/usr/bin/env bash
# Interactive content creation for Hugo
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONTENT_DIR="${ROOT_DIR}/content"

if ! command -v gum >/dev/null 2>&1; then
  echo "gum is required. Install via: mise install" >&2
  exit 1
fi

# Select content section
SECTIONS=()
while IFS= read -r dir; do
  SECTIONS+=("$(basename "$dir")")
done < <(find "$CONTENT_DIR" -mindepth 1 -maxdepth 1 -type d -not -name '.*' | sort)

SECTION="$(gum choose --header "Select content section" "${SECTIONS[@]}")"

# Enter content title
TITLE="$(gum input --placeholder "Enter page title" --header "New content in ${SECTION}/")"

if [ -z "$TITLE" ]; then
  echo "Title cannot be empty" >&2
  exit 1
fi

# Convert title to URL-safe slug
SLUG="$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')"

TARGET_DIR="${CONTENT_DIR}/${SECTION}/${SLUG}"
TARGET_FILE="${TARGET_DIR}/_index.md"

if [ -d "$TARGET_DIR" ]; then
  echo "Directory already exists: ${SECTION}/${SLUG}" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

cat > "$TARGET_FILE" <<EOF
---
title: "${TITLE}"
description: ""
---

EOF

echo "Created: content/${SECTION}/${SLUG}/_index.md"
