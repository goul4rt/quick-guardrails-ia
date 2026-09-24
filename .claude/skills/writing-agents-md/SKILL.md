---
name: writing-agents-md
description: Use when asked to write, rewrite, or bootstrap a repo's agent context file (AGENTS.md / CLAUDE.md), e.g. "escreva o CLAUDE.md", "crie o AGENTS.md", "documente os padrões do repo para o agente", or when applying-guardrails reaches block 1 of the CHECKLIST with no context file.
---

# Escrevendo o AGENTS.md de um repo

Referência: doc 01 do `quick-guardrails-ia` (três níveis acima deste arquivo, se veio via plugin). O resultado é sempre este par:

- **`AGENTS.md`**: o contrato. Fonte única, lida por Codex, Cursor, Copilot e pelo Claude Code.
- **`CLAUDE.md`**: `@AGENTS.md` na primeira linha, e abaixo só o que é exclusivo do Claude Code (hooks, skills, plan mode). Vazio abaixo do import é o caso normal.

Nunca o conteúdo nos dois arquivos: contratos duplicados divergem em silêncio.

O fluxo tem quatro fases, nesta ordem. Cada uma termina com o artefato dela entregue.

## Fase 1: fatos (você descobre, não pergunta)

Levante o que o repo responde sozinho: stack, comandos reais de build/test/lint/dev (rode-os; comando que falha não entra), estrutura de alto nível, convenções visíveis em código (nomes, padrão de serviço, testes), `README`, `CONTRIBUTING`, contexto que já exista (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.github/copilot-instructions.md`) e `git log` recente. Em repo grande, delegue a varredura a um subagente e fique só com a conclusão.

**Artefato**: lista de fatos com a evidência de cada um (arquivo:linha ou comando + saída), e a lista separada do que parece decisão mas o código não explica.

## Fase 2: entrevista (decisão se pergunta)

Rode as skills `grilling` e `domain-modeling` (juntas, é o que o `/grill-with-docs` do pacote `mattpocock-skills` faz) sobre a segunda lista da Fase 1: por que este padrão, qual gotcha já mordeu, o que o agente nunca deve fazer aqui. Uma pergunta por vez, cada uma com a sua hipótese a partir do código.

- Termo do domínio resolvido vai para o `CONTEXT.md`, na hora.
- Decisão já tomada em código vira ADR em `docs/adr/` **só** se passar nos três critérios: difícil de reverter, surpreendente sem contexto, fruto de trade-off real. As outras viram uma linha no `AGENTS.md` ou nada.
- Sem as skills instaladas: conduza a entrevista inline com as mesmas regras e avise que `claude plugins install mattpocock-skills` deixa isso reproduzível.

**Artefato**: `CONTEXT.md` e ADRs escritos, e as respostas que viram regra.

## Fase 3: escrita

Escreva o `AGENTS.md` seguindo o doc 01: postura no topo, regras checáveis num diff (com ✅/❌ quando couber), gotchas com o porquê, válvulas de escape nomeadas, regras de STOP, comandos que você rodou na Fase 1. **Teto declarado no próprio arquivo, abaixo de 200 linhas.** O que é longo e só vale para parte do código vira ponteiro (`docs/adr/`, `CONTEXT.md`, `.claude/rules/` por caminho), não texto inline.

Não entra: estrutura de pastas que o `ls` mostra, boas práticas genéricas, instrução de ferramenta da máquina do dev (rtk e afins vivem na config global), e qualquer coisa que o humano não confirmou.

Depois crie o `CLAUDE.md` com `@AGENTS.md` e, se houver, a seção exclusiva do Claude Code.

## Fase 4: auditoria

Rode a skill `claude-md-improver` (plugin `claude-md-management`) sobre o par. Aplique o que ela apontar de comando faltando, comando quebrado ou regra vaga; recuse o que ela sugerir que viole o teto ou repita o código. Em conflito, o doc 01 vence.

Entregue em branch + PR, com o relatório da auditoria no corpo. O merge é do dono.

## Erros comuns

| Erro | Correção |
|---|---|
| Escrever regra que o humano não confirmou ("parece que usam X") | Vira pergunta na Fase 2 ou fica de fora |
| Um ADR por decisão encontrada | Só os que passam nos três critérios; o resto é uma linha ou nada |
| `AGENTS.md` como symlink de `CLAUDE.md`, ou conteúdo copiado nos dois | `AGENTS.md` é a fonte; `CLAUDE.md` importa com `@AGENTS.md` |
| Colar a árvore de pastas e a lista de dependências | O agente lê o repo; o arquivo carrega só o que o repo não diz |
