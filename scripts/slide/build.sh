#!/usr/bin/env bash
#
# build.sh — Build Marp slides to PPTX format
#
# Marp supports splitting slides across multiple .md files. This script
# concatenates all .md files in a slide directory (sorted by filename)
# into a single input for marp-cli. Use numeric prefixes to control order:
#   00-frontmatter.md, 01-about.md, 02-services.md, ...
#
# The first file MUST contain the marp frontmatter (--- marp: true ---).
# Subsequent files contain only slide content separated by ---.
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

if ! command -v marp >/dev/null 2>&1; then
  echo "Error: marp not found. Run: mise install" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

build_slide() {
  local slide_dir="$1"
  local name
  name="$(basename "$slide_dir")"
  local output_file="${OUTPUT_DIR}/${name}.pptx"
  local tmp_file
  tmp_file="$(mktemp)"

  # Collect all .md files sorted by name
  local md_files=()
  while IFS= read -r f; do
    md_files+=("$f")
  done < <(find "$slide_dir" -maxdepth 1 -name "*.md" -type f | sort)

  if [ "${#md_files[@]}" -eq 0 ]; then
    echo "Skip: ${slide_dir} (no .md files)"
    return 0
  fi

  # Concatenate all .md files
  local first=true
  for f in "${md_files[@]}"; do
    if [ "$first" = true ]; then
      cat "$f" >> "$tmp_file"
      first=false
    else
      printf '\n' >> "$tmp_file"
      cat "$f" >> "$tmp_file"
    fi
  done

  echo "Building: ${name} (${#md_files[@]} files) -> ${output_file}"
  marp "$tmp_file" --pptx -o "$output_file"
  rm -f "$tmp_file"
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
