---
name: applying-guardrails
description: Use when asked to apply, audit, or bootstrap guardrails in a repo (CI gate, git hooks, supply chain, secrets scan, CLAUDE.md) — e.g. "aplique os guardrails", "rode o checklist", "deixe este repo seguro para agentes", "audite o projeto contra o guideline" — or when starting agent work in a repo that has none of them.
---

# Aplicando guardrails em um repo

Referência: o repo `metodologias-desenvolvimento-ia`. Se esta skill veio via plugin, o guideline completo já está no disco — `CHECKLIST.md`, `docs/` e `templates/` ficam três níveis acima deste arquivo. Senão: clone local (ex.: `~/workspace/metodologias-desenvolvimento-ia`) ou clone raso de `github.com/goul4rt/metodologias-desenvolvimento-ia`. Esta skill não resume o guideline; ela impõe o fluxo sobre ele: **auditar → decidir → implementar**, nessa ordem, cada fase com seu artefato. Implementar sem auditar é o modo de falha nº 1 — competência técnica não substitui o fluxo.

## Fase 1 — Auditoria (sempre primeiro)

Rode o `CHECKLIST.md` da referência contra o repo-alvo, item a item, executando a **verificação objetiva** indicada em cada item (rode o comando, não presuma).

**Artefato obrigatório**: o checklist preenchido — ✅ / ❌ / `n/a (condição não vale)` — com evidência por item (comando rodado + resultado). Sem esse artefato entregue, a fase não terminou e nenhum arquivo é criado.

## Fase 2 — Decisão humana (gate)

Apresente os gaps **em ordem de impacto**, com a proposta de implementação de cada um (template de origem + adaptações). Pare e espere decisão para:

- todo item ⚠️ ou que envolve custo (doc 09 da referência) — ex.: branch protection em repo privado;
- a variante do hook de push (bloquear todo push × só forçado);
- conteúdo que exige conhecimento do projeto: **`CLAUDE.md` se escreve com o humano** — regras, gotchas e anti-patterns vêm do projeto real; propor esqueleto é ok, inventar conteúdo não é.

Usuário indisponível ou sessão autônoma? Entregue auditoria + propostas e **pare aí**. Implementar tudo sozinho é o erro, não o zelo.

## Fase 3 — Implementação (só o aprovado)

- Branch + PR por bloco do checklist; nunca commit ou merge direto na mainline — nem "porque não há remoto".
- **Adapte, não copie**: resolva todo placeholder `⟨...⟩`, siga o `ADAPTING.md`/doc do template; os checks do gate refletem o stack real do alvo (não infle com ferramentas que o projeto não tem).
- Dívida zerada **no mesmo PR** que liga o gate; canário entra junto do hook que ele testa.
- Refaça a verificação objetiva do CHECKLIST após implementar cada item — evidência fresca, não "deve funcionar".
- O que ficou de fora vira **gap consciente registrado** (no PR ou em issue), nunca omissão silenciosa.

## Erros comuns (observados em baseline real)

| Erro | Correção |
|---|---|
| Ir direto à implementação, auditoria vira relatório ad-hoc no final | Fase 1 entrega o CHECKLIST preenchido antes de qualquer arquivo ser tocado |
| Inventar `CLAUDE.md` completo (branches, STOPs) para projeto desconhecido | Esqueleto + perguntas ao humano; conteúdo real vem do projeto |
| Merge direto na mainline "porque não há remoto/PR" | Deixe a branch pronta e reporte; o merge é decisão do dono |
| Decidir sozinho item ⚠️/custo e só documentar depois | Documentar a decisão não substitui pedir a decisão |
