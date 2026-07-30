#!/bin/bash
# Anti-drift de docs (doc 11, "parentes do mesmo princípio"): todo link relativo
# em README/CHECKLIST/docs deve apontar para arquivo que existe no repo.
# Impede o contrato de contexto de citar infra fantasma — o modo de falha do
# caso 2 do doc 11 (README apontando para diretório que nunca existiu).
#
# Uso: scripts/check-doc-paths.sh [raiz]   (default: .)
# Sai 0 se todos os links resolvem; 1 se qualquer um estiver quebrado.
#
# Escopo deliberado: README.md, CHECKLIST.md e docs/*.md. Os .md de templates/
# ficam fora — citam caminhos do projeto-alvo (placeholders), não deste repo.
set -u
ROOT="${1:-.}"
FAIL=0

for file in "$ROOT"/README.md "$ROOT"/CHECKLIST.md "$ROOT"/docs/*.md; do
  [ -f "$file" ] || continue
  dir=$(dirname "$file")
  while IFS= read -r target; do
    case "$target" in
      http://* | https://* | mailto:* | \#*) continue ;;
    esac
    path="${target%%#*}" # âncora não é caminho
    [ -z "$path" ] && continue
    if [ ! -e "$dir/$path" ]; then
      echo "LINK QUEBRADO em $file: ($target)" >&2
      FAIL=1
    fi
  done < <(grep -oE '\]\([^)]+\)' "$file" | sed 's/^](//; s/)$//')
done

if [ "$FAIL" -ne 0 ]; then
  echo "drift de docs: link(s) apontando para caminho inexistente" >&2
  exit 1
fi
echo "docs íntegros: todos os links relativos resolvem"
exit 0
