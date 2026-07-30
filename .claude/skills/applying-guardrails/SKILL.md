---
name: applying-guardrails
description: Use when asked to apply, audit, or bootstrap guardrails in a repo (CI gate, git hooks, supply chain, secrets scan, CLAUDE.md), e.g. "aplique os guardrails", "rode o checklist", "deixe este repo seguro para agentes", "audite o projeto contra o guideline", or when starting agent work in a repo that has none of them.
---

# Aplicando guardrails em um repo

Referência: o repo `quick-guardrails-ia`. Se esta skill veio via plugin, o guideline completo já está no disco: `CHECKLIST.md`, `docs/` e `templates/` ficam três níveis acima deste arquivo. Senão, use um clone local (ex.: `~/workspace/quick-guardrails-ia`) ou um clone raso de `github.com/goul4rt/quick-guardrails-ia`. Esta skill não resume o guideline; ela impõe o fluxo sobre ele: **auditar → decidir → implementar**, nessa ordem, cada fase com seu artefato. Implementar sem auditar é o modo de falha nº 1, e competência técnica não substitui o fluxo.

## Fase 1: auditoria (sempre primeiro)

Rode o `CHECKLIST.md` da referência contra o repo-alvo, item a item, executando a **verificação objetiva** indicada em cada item (rode o comando, não presuma).

Rodar o comando não basta: o comando também erra.

- **Verificação negativa exige caso de controle.** Grep vazio e contador zero passam igual com repo limpo e com comando quebrado. Antes de marcar ✅, rode o mesmo comando contra uma linha fabricada que deveria casar; se não casar, o gap é o comando. Foi assim que uma auditoria real marcou "deps pinadas" com 30 de 36 deps em `^`.
- **Item que depende de execução se verifica pelo run** (`gh run list --workflow <arquivo> --limit 5`), não pela leitura do YAML. Gate suspenso por billing lê como protegido.

**Artefato obrigatório**: o checklist preenchido, com ✅ / ❌ / `n/a (condição não vale)` e evidência por item (comando rodado + resultado). Sem esse artefato entregue, a fase não terminou e nenhum arquivo é criado.

## Fase 2: decisão humana (gate)

Apresente os gaps **em ordem de impacto**, com a proposta de implementação de cada um (template de origem + adaptações).

Impacto é **dano × probabilidade no histórico daquele repo**, não a ordem do checklist. Antes de ordenar, leia o histórico (issues, `STATUS.md`, incidentes, o que já vazou ou já se perdeu) e olhe o que está a um commit de distância do desastre: um `.env` com credencial de produção na raiz, separado do push só pelo `.gitignore`, coloca scan de secrets acima dos hooks de git, por mais que hook seja o item mais visível. Se o humano aprovar só o primeiro bloco, ele precisa ser o que mais dói perder.

Depois conduza as decisões como **entrevista, não formulário**:

- **Fato se descobre, decisão se pergunta.** O que um comando ou arquivo responde (stack, remoto, público × privado), descubra você mesmo; só trade-off, custo e preferência vão para o humano.
- **Uma decisão por vez**, na ordem das dependências entre elas (ex.: público × privado antes de branch protection, que depende do custo). Várias perguntas de uma vez confundem.
- **Toda pergunta chega com a sua recomendação e o porquê** ("Recomendo bloquear só push forçado porque…"). Espere a resposta antes da próxima.

São sempre decisões humanas: todo item ⚠️ ou com custo (doc 09 da referência); a variante do hook de push (todo push × só forçado); e conteúdo que exige conhecimento do projeto, porque **`CLAUDE.md` se escreve com o humano** (propor esqueleto é ok, inventar conteúdo não é).

Nada de implementar até o humano confirmar que o entendimento é comum. Usuário indisponível ou sessão autônoma? Entregue auditoria + propostas com a recomendação registrada por decisão pendente e **pare aí**. Implementar tudo sozinho é o erro, não o zelo.

## Fase 3: implementação (só o aprovado)

- Branch + PR por bloco do checklist; nunca commit ou merge direto na mainline, nem "porque não há remoto". **Agrupe blocos conforme o time**: com um mantenedor só, três PRs temáticos são tão revisáveis quanto oito e muito mais baratos de mergear em cascata. Cerimônia escala com o tamanho do time, não com o tamanho do checklist.
- **Adapte, não copie**: resolva todo placeholder `⟨...⟩`, siga o `ADAPTING.md`/doc do template; os checks do gate refletem o stack real do alvo (não infle com ferramentas que o projeto não tem).
- Dívida zerada **no mesmo PR** que liga o gate; canário entra junto do hook que ele testa.
- Refaça a verificação objetiva do CHECKLIST após implementar cada item: evidência fresca, não "deve funcionar".
- O que ficou de fora vira **gap consciente registrado** (no PR ou em issue), nunca omissão silenciosa.

## Erros comuns (observados em baseline real)

| Erro | Correção |
|---|---|
| Ir direto à implementação, auditoria vira relatório ad-hoc no final | Fase 1 entrega o CHECKLIST preenchido antes de qualquer arquivo ser tocado |
| Inventar `CLAUDE.md` completo (branches, STOPs) para projeto desconhecido | Esqueleto + perguntas ao humano; conteúdo real vem do projeto |
| Merge direto na mainline "porque não há remoto/PR" | Deixe a branch pronta e reporte; o merge é decisão do dono |
| Decidir sozinho item ⚠️/custo e só documentar depois | Documentar a decisão não substitui pedir a decisão |
| Marcar ✅ porque o grep voltou vazio | Verificação negativa precisa do caso de controle que prova que ela detecta |
| Marcar ✅ de gate lendo o YAML | Confira os últimos runs; workflow que não executa lê como proteção |
| Encher o `CLAUDE.md` seguindo os subitens do bloco 1 | Cada seção nova aponta o que saiu; o arquivo tem teto |
