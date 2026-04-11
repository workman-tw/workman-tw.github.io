#!/usr/bin/env bash
#
# build.sh — Build Marp slides to PPTX format
#
# USAGE
#   ./scripts/slide/build.sh                    # build all slides
#   ./scripts/slide/build.sh docs/slides/intro   # build specific slide
#   just slide-build                             # run via just
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_DIR="${ROOT_DIR}/static/downloads"
SLIDES_DIR="${ROOT_DIR}/docs/slides"

if ! command -v npx >/dev/null 2>&1; then
  echo "Error: npx not found. Install Node.js via: mise install" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

build_slide() {
  local slide_dir="$1"
  local slide_file="${slide_dir}/slide.md"
  local name
  name="$(basename "$slide_dir")"
  local output_file="${OUTPUT_DIR}/${name}.pptx"

  if [ ! -f "$slide_file" ]; then
    echo "Skip: ${slide_dir} (no slide.md)"
    return 0
  fi

  echo "Building: ${name} -> ${output_file}"
  npx --yes @marp-team/marp-cli "$slide_file" --pptx -o "$output_file"
  echo "Done: ${output_file}"
}

if [ "$#" -gt 0 ]; then
  for dir in "$@"; do
    build_slide "$dir"
  done
else
  while IFS= read -r dir; do
    build_slide "$dir"
  done < <(find "$SLIDES_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
fi
