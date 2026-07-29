#!/usr/bin/env bash
# Anexa arquivo(s) a uma issue do Jira via REST API — o caminho suportado para
# automação (o fluxo de mídia do browser usa token efêmero e não serve aqui).
#
# Uso:  scripts/jira-attach.sh <ISSUE-KEY> <arquivo> [arquivo...]
# Ex.:  scripts/jira-attach.sh PROJ-123 docs/qa-logs/PROJ-123/*.png
#
# Credenciais: JIRA_USERNAME + TOKEN_FOR_JIRA do .env (o mesmo par usado pelo
# MCP do Jira). JIRA_URL define a instância (ou ajuste o default abaixo).
set -euo pipefail

[ $# -ge 2 ] || {
  echo "uso: $0 <ISSUE-KEY> <arquivo> [arquivo...]" >&2
  exit 1
}

issue="$1"
shift

root="$(cd "$(dirname "$0")/.." && pwd)"
env_file="$root/.env"
[ -f "$env_file" ] || {
  echo "erro: .env não encontrado em $env_file" >&2
  exit 1
}

user="$(grep -E '^JIRA_USERNAME=' "$env_file" | cut -d= -f2-)"
token="$(grep -E '^TOKEN_FOR_JIRA=' "$env_file" | cut -d= -f2-)"
[ -n "$user" ] && [ -n "$token" ] || {
  echo "erro: faltam JIRA_USERNAME/TOKEN_FOR_JIRA no .env" >&2
  exit 1
}
base="${JIRA_URL:-https://SUA-INSTANCIA.atlassian.net}"

# Um -F por arquivo — a API aceita vários anexos num único request.
files=()
for f in "$@"; do
  [ -f "$f" ] || {
    echo "erro: arquivo não encontrado: $f" >&2
    exit 1
  }
  files+=(-F "file=@$f")
done

resp="$(curl -sS -w $'\n%{http_code}' -u "$user:$token" \
  -H 'X-Atlassian-Token: no-check' \
  "${files[@]}" \
  "$base/rest/api/3/issue/$issue/attachments")"

code="${resp##*$'\n'}"
body="${resp%$'\n'*}"
echo "$body"
[ "$code" = 200 ] || {
  echo "erro: upload falhou (HTTP $code) em $issue" >&2
  exit 1
}
