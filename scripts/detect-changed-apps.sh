#!/usr/bin/env bash
set -euo pipefail

base="${1:-}"
head_ref="${2:-HEAD}"

if [[ -z "$base" ]]; then
  if git rev-parse HEAD^ >/dev/null 2>&1; then
    base="HEAD^"
  else
    base="$(git hash-object -t tree /dev/null)"
  fi
fi

if [[ "$base" =~ ^0+$ ]] || ! git cat-file -e "$base" 2>/dev/null; then
  base="$(git hash-object -t tree /dev/null)"
fi

changed_files="$(git diff --name-only "$base" "$head_ref" || true)"
apps=()

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  if [[ "$file" =~ ^apps/([^/]+)/ ]]; then
    app="${BASH_REMATCH[1]}"
    if [[ ! " ${apps[*]} " =~ " ${app} " ]]; then
      apps+=("$app")
    fi
  fi
done <<<"$changed_files"

if [[ "${#apps[@]}" -eq 0 ]]; then
  echo "[]"
  exit 0
fi

printf '%s\n' "${apps[@]}" | jq -R . | jq -cs .
