#!/usr/bin/env bash
# render.sh — render a Markmap .md to standalone interactive HTML.
# Usage: render.sh <md-path> [html-path]
# Exit codes: 0 ok | 1 usage | 2 md not found | 3 npx missing | 4 render failed
set -euo pipefail

md="${1:-}"
if [ -z "$md" ]; then
  echo "usage: render.sh <md-path> [html-path]" >&2
  exit 1
fi

if [ ! -f "$md" ]; then
  echo "error: markmap file not found: $md" >&2
  exit 2
fi

html="${2:-}"
if [ -z "$html" ]; then
  # swap trailing .md for .html (handles foo.mindmap.md -> foo.mindmap.html)
  html="${md%.md}.html"
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "error: npx not found; the .md is safe but HTML was not rendered." >&2
  echo "to render manually, install Node.js then run:" >&2
  echo "  npx --yes markmap-cli \"$md\" -o \"$html\" --no-open" >&2
  exit 3
fi

# send npx chatter to stderr; stdout must stay just the html path (callers capture it)
if ! npx --yes markmap-cli "$md" -o "$html" --no-open >&2; then
  echo "error: markmap-cli failed; the .md is safe but HTML was not rendered." >&2
  exit 4
fi

echo "$html"
