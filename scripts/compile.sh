#!/usr/bin/env bash

set -euo pipefail

SINGBOX_BIN=${SINGBOX_BIN:-sing-box}
SOURCE_DIR=${1:-rules}
OUTPUT_DIR=${2:-dist}

if ! command -v "$SINGBOX_BIN" >/dev/null 2>&1; then
  echo "error: sing-box executable '$SINGBOX_BIN' not found in PATH" >&2
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "error: source directory '$SOURCE_DIR' does not exist" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

shopt -s nullglob globstar
rule_files=("$SOURCE_DIR"/**/*.json)
shopt -u globstar

if [[ ${#rule_files[@]} -eq 0 ]]; then
  echo "no JSON rule-set source files found under '$SOURCE_DIR'" >&2
  exit 1
fi

for file in "${rule_files[@]}"; do
  rel="${file#$SOURCE_DIR/}"
  rel_no_ext="${rel%.json}"
  out="$OUTPUT_DIR/$rel_no_ext.srs"
  mkdir -p "$(dirname "$out")"
  echo "compiling $file -> $out"
  "$SINGBOX_BIN" rule-set compile "$file" "$out"
done

echo "done. Generated $(find "$OUTPUT_DIR" -name '*.srs' | wc -l | tr -d ' ') file(s) in '$OUTPUT_DIR'."
