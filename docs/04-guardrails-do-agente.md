# 04 — Guardrails do agente: restrição no harness, não no prompt

Pedir no prompt "nunca dê force push" é probabilístico — funciona até o dia em que não funciona. Hook de `PreToolUse` é **determinístico**: o comando é bloqueado antes de executar, sempre, independente do que o modelo "decidiu".

Templates: [`settings.json`](../templates/.claude/settings.json) · [`block-dangerous-git.sh`](../templates/.claude/hooks/block-dangerous-git.sh) · [`eslint-fix-edited.sh`](../templates/.claude/hooks/eslint-fix-edited.sh)

## Guardrails de time, não individuais

O `.claude/settings.json` e os hooks são **versionados no repo**. Todo dev (e todo agente) que clona herda os mesmos guardrails — não é configuração pessoal de quem "lembrou de instalar". O mesmo arquivo declara os plugins habilitados (`enabledPlugins`), fechando o pacote de onboarding.

## `PreToolUse`: bloquear git destrutivo

O hook recebe o comando Bash como JSON no stdin, compara com uma lista de padrões e, ao casar, sai com **código 2** + mensagem no stderr — o Claude Code cancela a execução e o agente vê o motivo.

Padrões bloqueados no template:

| Padrão | Protege contra |
|---|---|
| `push --force` / `push -f` / `--force-with-lease` | Reescrever histórico remoto |
| `reset --hard` | Descartar commits/estado local |
| `clean -f` / `-fd` | Apagar arquivos não rastreados |
| `branch -D` | Deletar branch não mergeada |
| `checkout .` / `restore .` | Descartar mudanças não commitadas |

**Decisão de calibragem — push total ou só force?** Duas variantes legítimas:

- **Bloquear todo `git push`** (variante do repo de origem): push vira ação exclusivamente humana. Máxima segurança; o agente prepara, o humano publica.
- **Bloquear só push forçado** (variante do template): o agente pode publicar branch de trabalho, mas nunca reescrever histórico. Menos fricção em fluxo com PRs.

A escolha depende de quanto o fluxo do time depende do agente abrir PRs sozinho. Note que `git checkout <branch>` (troca de branch) **não** é afetado — o padrão exige o `.` literal.

## `PostToolUse`: auto-fix de lint no arquivo editado

O segundo hook roda ESLint `--fix` **só no arquivo que acabou de ser editado** (`Edit|Write`). As propriedades que fazem dele um bom hook — e que valem como checklist para qualquer hook de `PostToolUse`:

1. **Rápido**: um arquivo, nunca o projeto inteiro.
2. **Nunca bloqueia**: `exit 0` sempre; o que o `--fix` não resolve fica para o gate.
3. **Silencioso**: output descartado — não polui o contexto do agente.
4. **Degrada bem**: sem `jq`, sem o arquivo (deletado/renomeado), fora de `.ts/.tsx` → sai quieto. `--no-install`: usa o ESLint do projeto, nunca baixa nada.

## Limitação conhecida: falso positivo por substring

O matching é **substring ingênua sobre o comando inteiro** — não parseia se é de fato uma invocação de git. Caso real: um `git commit` foi bloqueado porque a **mensagem do commit** citava "reset --hard" como texto descritivo (documentação de... guardrails).

Trade-offs de conviver com isso:

- É o lado certo do erro: falso positivo custa uma reformulação; falso negativo custa histórico perdido.
- Contorno simples: não citar os padrões literais em mensagens de commit/heredocs (parafrasear).
- A alternativa (parsear shell de verdade) não paga o custo — o hook deixaria de ser 25 linhas auditáveis de bash.

O ponto meta: **todo guardrail simples tem falsos positivos; documente-os em vez de sofisticar o guardrail.**

**Fonte**: PR [#141](https://github.com/Instivo/instivo-pesquisador-app/pull/141) + calibragem da variante force-only em uso no `goul4rt/delfus` (2026-07).
