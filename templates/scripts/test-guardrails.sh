#!/bin/bash
# Canário do guardrail: prova que o hook bloqueia o que deve bloquear (exit 2)
# e deixa passar o que deve passar (exit 0). Guardrail sem canário quebra em
# silêncio e continua verde — rode isto no CI (ver docs/11-teste-o-guardrail.md).
#
# Uso: scripts/test-guardrails.sh [caminho-do-hook]
# Sai 0 se todos os casos batem; 1 se qualquer caso diverge.

set -u
HOOK="${1:-.claude/hooks/block-dangerous-git.sh}"
FAIL=0

if [ ! -f "$HOOK" ]; then
  echo "hook não encontrado: $HOOK" >&2
  exit 1
fi

# Invoca o hook REAL, com o mesmo JSON que o Claude Code envia.
# jq monta o JSON — nunca interpole comando em string de JSON à mão.
rc_of() {
  jq -cn --arg c "$1" '{tool_input: {command: $c}}' | bash "$HOOK" >/dev/null 2>&1
  echo $?
}

# Exit code estrito: 2 é bloqueio; qualquer outro não-zero é o hook quebrado
# (crash não é bloqueio — é exatamente o modo de falha que o canário existe pra pegar).
expect_block() {
  local rc
  rc=$(rc_of "$1")
  if [ "$rc" -ne 2 ]; then
    echo "FALSO NEGATIVO (esperava exit 2, veio $rc): $1" >&2
    FAIL=1
  fi
}

expect_pass() {
  local rc
  rc=$(rc_of "$1")
  if [ "$rc" -ne 0 ]; then
    echo "FALSO POSITIVO (esperava exit 0, veio $rc): $1" >&2
    FAIL=1
  fi
}

# --- must-block: se algum destes passar, o guardrail não guarda nada ---
expect_block "git push --force origin main"
expect_block "git push -f"
expect_block "git push origin main --force-with-lease"
expect_block "git reset --hard HEAD~1"
expect_block "git clean -fd"
expect_block "git clean -f"
expect_block "git branch -D feature-x"
expect_block "git checkout ."
expect_block "git restore ."
# Falso positivo documentado (doc 04) — fixado de propósito: o hook casa
# substring, então mensagem de commit citando o padrão bloqueia. Se este caso
# um dia falhar, a limitação documentada mudou — atualize o doc junto.
expect_block "git commit -m 'docs: nunca rode reset --hard em branch compartilhada'"

# --- must-pass: o outro lado — falso positivo aqui mata a confiança no gate ---
expect_pass "git push origin feature-branch"
expect_pass "git checkout feature-branch"
expect_pass "git branch -d merged-branch"
expect_pass "git clean -n"
expect_pass "git restore --staged src/app.ts"
expect_pass "git status"
expect_pass "npm run build"

if [ "$FAIL" -ne 0 ]; then
  echo "canário: guardrail divergiu do esperado" >&2
  exit 1
fi
echo "canário: todos os casos ok ($HOOK)"
exit 0
