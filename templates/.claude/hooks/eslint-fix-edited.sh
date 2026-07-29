#!/usr/bin/env bash
# PostToolUse(Edit|Write) hook: auto-fix the file just edited with ESLint.
#
# Runs only on .ts/.tsx files, only on the single file touched (fast — never the
# whole project), and never blocks the edit: fixable issues are applied silently;
# anything unfixable is left for `npm run lint` / lint-staged. All output dropped.

input=$(cat)

# Need jq to pull the file path out of the hook payload; bail quietly if missing.
command -v jq >/dev/null 2>&1 || exit 0
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

case "$file" in
  *.ts | *.tsx) ;;
  *) exit 0 ;;
esac

# File may have been deleted/renamed between the edit and this hook.
[ -f "$file" ] || exit 0

# --no-install: use the project's eslint from node_modules; never download.
npx --no-install eslint --fix "$file" >/dev/null 2>&1

exit 0
