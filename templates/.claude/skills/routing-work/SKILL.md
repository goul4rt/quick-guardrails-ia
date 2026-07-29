---
name: routing-work
description: Use when starting any development task in ⟨seus repos⟩, when deciding which process skills to invoke, or when a change touches more than one repo.
---

# Roteamento de trabalho

Cerimônia escala com o tamanho do trabalho, não com a vontade de rigor. Decisão e spec vivem num lugar só; código e gates vivem em cada repo.

## Tiers — classifique ANTES de invocar qualquer skill

| Tier | Critério observável | Fluxo |
|---|---|---|
| **T0 trivial** | 1 arquivo, sem lógica nova (typo, doc, config) | localizar a ocorrência → editar → gate do repo → commit em branch. Zero specs/issues/planos. |
| **T1 bug** | comportamento errado reportado | ⟨skill de debugging sistemático⟩ → teste de regressão → verificação |
| **T2 feature 1-sessão** | 1 repo, cabe numa sessão, não precisa do board | ⟨brainstorm curto⟩ → ⟨stress-test da decisão⟩ → TDD inline → ⟨review⟩ → verificação. Nenhum artefato de plano persistente. |
| **T3 multi-sessão / cross-repo** | sobrevive à sessão OU toca 2+ repos OU deve aparecer no board | ⟨stress-test⟩ (+ ADR se render decisão de arquitetura) → spec → tickets → por sessão: implementar UM ticket com TDD → ⟨review⟩ → verificação |
| **T4 épico** | maior que qualquer sessão consegue segurar | explorar até o caminho clarear → degrada para T3 |

**T2 vs T3, na dúvida:** se amanhã outra sessão (ou outra instância) precisar continuar o trabalho, é T3.

## Regras cross-repo (T3 tocando 2+ repos)

1. **Spec-pai SEMPRE no repo dono do contrato** (quem define schema/API), mesmo em feature majoritariamente do outro repo. Sub-issues por repo, cross-repo.
2. A spec-pai tem seção **Contrato**: delta de schema, shape dos endpoints (rota/request/response), ordem de deploy.
3. Ordem sempre **contrato → provedor → consumidor**. Ticket do consumidor nasce `blocked by` o ticket do provedor.
4. **Contrato muda SÓ pelo repo dono**; os demais só leem. Mudança backward-compatible; deploy do dono primeiro.
5. **1 sessão = 1 ticket = 1 repo.** Contexto cruza via handoff (issue/doc), nunca via uma sessão editando dois checkouts.

## Decisões fixas

- **UM reviewer por diff** — ⟨sua skill de review⟩; não somar reviewers.
- Verificação com evidência fresca antes de qualquer "pronto", em todo tier ≥ T1.
- ⟨proibições do seu contexto — ex.: worktrees se você roda múltiplas instâncias no mesmo checkout⟩

## "Verde" por repo

- **⟨repo A⟩**: ⟨comandos do gate local⟩ ⟨— comparado ao baseline, se a suíte carrega falhas pré-existentes⟩
- **⟨repo B⟩**: ⟨comandos do gate local⟩

## Erros comuns

| Erro | Correção |
|---|---|
| Spec duplicada (doc local + issue) | Um artefato só: T2 = nenhum persistente; T3 = issue no tracker |
| Spec-pai criada no repo consumidor | Pai no dono do contrato; o resto é sub-issue |
| Dois reviewers no mesmo diff | Só ⟨review⟩ |
| "Qualidade máxima" = mais processo | Qualidade = grounding + stress-test + TDD + review + evidência fresca |
