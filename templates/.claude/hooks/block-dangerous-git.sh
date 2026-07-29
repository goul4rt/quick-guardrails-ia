#!/bin/bash
# PreToolUse(Bash) hook: bloqueia comandos git destrutivos antes de executarem.
#
# Variante "force-only": push normal e troca de branch passam livres; push
# forçado e comandos que descartam trabalho são barrados (exit 2 → o Claude
# Code cancela a execução e mostra o motivo ao agente).
#
# Para a variante mais restritiva (bloquear TODO push), adicione "git push"
# à lista — push vira ação exclusivamente humana.
#
# Limitação conhecida: matching por substring no comando inteiro — texto livre
# (ex.: mensagem de commit citando um padrão) gera falso positivo. É o lado
# certo do erro; parafraseie a mensagem em vez de sofisticar o parser.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

DANGEROUS_PATTERNS=(
  "push.*--force"
  "push.*-f( |$)"
  "git reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \."
  "git restore \."
  "reset --hard"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: '$COMMAND' matches dangerous pattern '$pattern'. The user has prevented you from doing this." >&2
    exit 2
  fi
done

exit 0
