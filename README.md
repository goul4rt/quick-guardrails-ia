# Metodologias para desenvolvimento com IA

Práticas, guardrails e artefatos prontos para desenvolver software com agentes de IA (Claude Code) de forma **segura, reprodutível e auditável** — extraídos de trabalho real em produção.

**Guideline formal de 0 → funcionando sem orçamento**: regras locais (hooks, configs versionadas), ferramentas OSS e recursos públicos/gratuitos. A única base paga assumida é a assinatura do Claude Code que você já tem. Peça que exige serviço externo pago ou cobrança por token **não entra nos templates** — a regra de admissão e a tabela de custos estão no [doc 09](docs/09-custos.md).

Tudo aqui nasceu de uma sequência de PRs no `Instivo/instivo-pesquisador-app` (app React Native em produção), onde um agente de IA passou a trabalhar com gate de CI bloqueante, supply chain travada, guardrails de git e fluxo de task com evidência obrigatória:

| PR | Tema | Estado |
|---|---|---|
| [#123](https://github.com/Instivo/instivo-pesquisador-app/pull/123) | Gate de CI 100% bloqueante + pins exatos + Dependabot + auditoria mensal | Merged |
| [#125](https://github.com/Instivo/instivo-pesquisador-app/pull/125) | `npm audit fix` disciplinado (32 → 13 vulnerabilidades, sem `--force`) | Merged |
| [#130](https://github.com/Instivo/instivo-pesquisador-app/pull/130) | Lockfile dessincronizado — o gate pegou o problema real | Merged |
| [#131](https://github.com/Instivo/instivo-pesquisador-app/pull/131) | `paths-ignore` para docs + workflow no-op (pegadinha do required check) | Fechado sem merge |
| [#141](https://github.com/Instivo/instivo-pesquisador-app/pull/141) | Skills versionadas por hash + hooks de guardrails + `/task close` com evidência no Jira | Aberto |

## Princípios

1. **Gate bloqueante ou gate nenhum.** Check que não trava merge é decoração. Zere a dívida que impede o bloqueio *no mesmo PR* que cria o gate.
2. **Guardrail no harness, não no prompt.** Instrução em prompt é probabilística; hook `PreToolUse` é determinístico. O que não pode acontecer, bloqueie por código.
3. **Reprodutibilidade por hash.** Dependências pinadas na versão exata; skills de IA fixadas por hash em lockfile. Upgrade é PR explícito, nunca efeito colateral.
4. **Evidência, não afirmação.** Task só fecha com prova visual (screenshot + log) por critério de aceite. Falhou? Reporta como falhou — nunca maquia.
5. **Não presuma, não invente.** Sem critérios de aceite → pergunta. Sem PR aberto → pede. MCP desconectado → avisa e para. O agente expõe trade-offs em vez de decidir em silêncio.
6. **Exceções são documentadas, não escondidas.** Fugiu da convenção de propósito? A decisão e o porquê ficam registrados no PR.

## Mapa do repositório

### Guias (`docs/`)

| Doc | Conteúdo |
|---|---|
| [01 — Contexto do projeto](docs/01-contexto-do-projeto.md) | `CLAUDE.md` como contrato operacional do agente: regras objetivas, gotchas, anti-patterns |
| [02 — Gate de CI](docs/02-gate-de-ci.md) | Gate de PR 100% bloqueante: ordem dos checks, concurrency, e a armadilha do required check com `paths-ignore` |
| [03 — Supply chain](docs/03-supply-chain.md) | Pins exatos, Dependabot, auditoria mensal, `npm audit fix` disciplinado e lockfile drift |
| [04 — Guardrails do agente](docs/04-guardrails-do-agente.md) | Hooks `PreToolUse`/`PostToolUse`: bloquear git destrutivo, auto-fix de lint, limitações conhecidas |
| [05 — Skills versionadas](docs/05-skills-versionadas.md) | `skills-lock.json`: skills de IA fixadas por hash, restauradas no `npm install` |
| [06 — Fluxo de task](docs/06-fluxo-de-task.md) | `/task` e `/task close`: da issue do Jira ao merge com evidência e review duplo |
| [07 — Lições aprendidas](docs/07-licoes-aprendidas.md) | Estudo de caso: o que os 5 PRs ensinaram (incluindo o que não foi adotado) |
| [08 — Segurança no gate](docs/08-seguranca-no-gate.md) | Scanner determinístico bloqueia, IA recomenda: gitleaks free + review local + triagem de falha |
| [09 — Custos e regra de admissão](docs/09-custos.md) | Free por padrão: o que é free, o que é "free com pegadinha", o que ficou de fora e por quê |

### Artefatos prontos (`templates/`)

```
templates/
├── .github/
│   ├── workflows/ci.yml            # gate de PR bloqueante (adapte os checks à sua stack)
│   ├── workflows/ci-docs-noop.yml  # companheiro do paths-ignore (required check nunca trava)
│   ├── workflows/audit.yml         # npm audit mensal → abre/atualiza issue
│   ├── workflows/security.yml      # gitleaks CLI (free, bloqueante) — secrets no histórico
│   └── dependabot.yml              # semanal, majors excluídos, minor+patch agrupados
├── .claude/
│   ├── settings.json               # hooks + plugins versionados (guardrails de time)
│   └── hooks/
│       ├── block-dangerous-git.sh  # PreToolUse: bloqueia git destrutivo
│       └── eslint-fix-edited.sh    # PostToolUse: auto-fix só no arquivo editado
├── scripts/
│   ├── skills-install.mjs          # restaura skills do lock (postinstall seguro)
│   └── jira-attach.sh              # anexa evidência a issue do Jira via REST
└── .npmrc                          # save-exact=true
```

## Como adotar em um repositório novo

1. **Contexto**: escreva um `CLAUDE.md` enxuto com regras objetivas ([doc 01](docs/01-contexto-do-projeto.md)).
2. **Guardrails**: copie `templates/.claude/` e versione no repo ([doc 04](docs/04-guardrails-do-agente.md)).
3. **Gate**: adapte `templates/.github/workflows/ci.yml` à sua stack — e **zere a dívida antes de ligar o bloqueio** ([doc 02](docs/02-gate-de-ci.md)).
4. **Supply chain**: `.npmrc` com `save-exact`, pins exatos, `dependabot.yml` e `audit.yml` ([doc 03](docs/03-supply-chain.md)).
5. **Branch protection**: exija o check `ci` e bloqueie push direto na branch principal — sem isso o gate não trava nada (passo manual, precisa de admin).
6. **Fluxo**: crie um comando `/task` adaptado ao seu tracker ([doc 06](docs/06-fluxo-de-task.md)).
