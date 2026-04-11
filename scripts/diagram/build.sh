#!/usr/bin/env bash
#
# build.sh — Render mermaid .mmd files to SVG images
#
# USAGE
#   ./scripts/diagram/build.sh              # build all diagrams
#   ./scripts/diagram/build.sh infra-vertex  # build specific diagram (without .mmd)
#   just diagram-build                       # run via just
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIAGRAMS_DIR="${ROOT_DIR}/diagrams"
OUTPUT_DIR="${ROOT_DIR}/static/images/diagrams"

if ! command -v mmdc >/dev/null 2>&1; then
  echo "Error: mmdc not found. Run: mise install" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

build_diagram() {
  local mmd_file="$1"
  local name
  name="$(basename "$mmd_file" .mmd)"
  local output_file="${OUTPUT_DIR}/${name}.svg"

  echo "Rendering: ${name}.mmd -> ${output_file}"
  mmdc -i "$mmd_file" -o "$output_file" -b transparent
  echo "Done: ${output_file}"
}

if [ "$#" -gt 0 ]; then
  for name in "$@"; do
    mmd_file="${DIAGRAMS_DIR}/${name}.mmd"
    if [ ! -f "$mmd_file" ]; then
      echo "Error: ${mmd_file} not found" >&2
      exit 1
    fi
    build_diagram "$mmd_file"
  done
else
  while IFS= read -r f; do
    build_diagram "$f"
  done < <(find "$DIAGRAMS_DIR" -name "*.mmd" -type f | sort)
fi
