<p align="center">
  <img src="docs/assets/banner.png" alt="Metodologias para desenvolvimento com IA — instrução em prompt é probabilística; hook e gate são determinísticos" width="900">
</p>

<div align="center">

# Metodologias para desenvolvimento com IA

**Guardrails que não dependem do agente obedecer** — gate de CI bloqueante, hooks determinísticos, supply chain travada e evidência obrigatória, de 0 → funcionando **sem orçamento**.

[![ci](https://github.com/goul4rt/metodologias-desenvolvimento-ia/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/goul4rt/metodologias-desenvolvimento-ia/actions/workflows/ci.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![last commit](https://img.shields.io/github/last-commit/goul4rt/metodologias-desenvolvimento-ia)](https://github.com/goul4rt/metodologias-desenvolvimento-ia/commits/master)

</div>

Instrução em prompt é probabilística; hook e gate são determinísticos. Este repositório reúne práticas, guardrails e artefatos **prontos para copiar** para desenvolver software com agentes de IA (Claude Code) de forma segura, reprodutível e auditável — usando só regras locais, ferramentas OSS e recursos gratuitos. A única base paga assumida é a assinatura do Claude Code que você já tem; o que exige serviço pago ou cobrança por token **não entra nos templates** ([doc 09](docs/09-custos.md)).

Tudo aqui nasceu de trabalho real em **três codebases em produção** — um app mobile (React Native), um painel web (Next.js) e um bot (Node) — onde agentes de IA passaram a operar com gate de CI bloqueante, supply chain travada, guardrails de git e fluxo de task com evidência obrigatória. Os números e as lições são reais; as referências internas foram generalizadas para servir a qualquer projeto ([doc 07](docs/07-licoes-aprendidas.md)). E o repo come o próprio dogfood: o CI daqui roda o canário dos guardrails dos templates e checa que nenhum doc cita caminho fantasma.

## Comece em 60 segundos

**Auditar um repo existente (com um agente):** instale a skill como plugin do Claude Code — ela impõe o fluxo certo em qualquer repo:

```text
/plugin marketplace add goul4rt/metodologias-desenvolvimento-ia
/plugin install guardrails@metodologias
# em qualquer repo: "aplique os guardrails" / "rode o checklist"
```

Sem plugin, o mesmo efeito via clone + symlink (`ln -s <este-repo>/.claude/skills/applying-guardrails ~/.claude/skills/`) — ou só o prompt da seção [Usando com um agente de IA](#usando-com-um-agente-de-ia).

**Adotar do zero:** siga os 6 passos de [Como adotar em um repositório novo](#como-adotar-em-um-repositório-novo).

**Só quer um artefato:** tudo em [`templates/`](templates/) é copiável — cada arquivo aponta o doc que explica o porquê de cada decisão.

## O que muda na prática

Teste real (baseline documentado na criação da skill): o mesmo modelo, o mesmo pedido — *"aplique os guardrails neste repo"* — num projeto Node recém-criado.

| Sem o guideline | Com a skill `applying-guardrails` |
|---|---|
| Implementou 15 arquivos de uma vez, sem perguntar nada | Auditou primeiro: CHECKLIST preenchido ✅/❌/n-a, com evidência (comando + resultado) por item |
| Inventou um `CLAUDE.md` inteiro (convenções de branch, regras de STOP) para um projeto que não conhece | Propôs só o esqueleto e listou as perguntas que apenas o dono do projeto responde |
| Commitou e mergeou direto na `main` | Não tocou em um arquivo sequer antes da aprovação |
| Decidiu sozinho itens com custo e trade-off | Parou no gate de decisão humana: variante de push, branch protection, autorização de install |

A diferença não é o modelo — é o processo imposto por guardrail: **auditar → decidir → implementar**, cada fase com artefato obrigatório.

## Princípios

1. **Gate bloqueante ou gate nenhum.** Check que não trava merge é decoração. Zere a dívida que impede o bloqueio *no mesmo PR* que cria o gate.
2. **Guardrail no harness, não no prompt.** Instrução em prompt é probabilística; hook `PreToolUse` é determinístico. O que não pode acontecer, bloqueie por código.
3. **Reprodutibilidade por hash.** Dependências pinadas na versão exata; skills de IA fixadas por hash em lockfile. Upgrade é PR explícito, nunca efeito colateral.
4. **Evidência, não afirmação.** Task só fecha com prova visual (screenshot + log) por critério de aceite. Falhou? Reporta como falhou — nunca maquia.
5. **Não presuma, não invente.** Sem critérios de aceite → pergunta. Sem PR aberto → pede. MCP desconectado → avisa e para. O agente expõe trade-offs em vez de decidir em silêncio.
6. **Exceções são documentadas, não escondidas.** Fugiu da convenção de propósito? A decisão e o porquê ficam registrados no PR.
7. **Guardrail também é código — sem teste, quebra em silêncio e continua verde.** Cada gate tem um canário (caso mau que deve reprovar, caso bom que deve passar) rodando no CI.

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
| [10 — Guardrails além do CI](docs/10-guardrails-alem-do-ci.md) | O espectro de enforcement: hooks, automação de invariante, regras de STOP, roteamento por tiers, memória |
| [11 — Teste o guardrail](docs/11-teste-o-guardrail.md) | Canário por gate: must-block/must-pass no CI — guardrail sem teste quebra em silêncio |
| [12 — Fronteira runtime](docs/12-fronteira-runtime.md) | Guardrails de dev × de runtime de LLM: o que transferiu, e as opções OSS (com ressalvas) para quem constrói produto |
| [13 — Evidências da literatura](docs/13-evidencias-da-literatura.md) | Os números públicos (Veracode, GitClear, USENIX, DORA, RCTs) que sustentam cada doc — e o que a literatura recomenda mas ficou fora por custo |
| [14 — Força de teste](docs/14-forca-de-teste.md) | Cobertura mede execução, não verificação: mutation testing, property-based testing e cobertura no código novo do PR |

### Artefatos prontos (`templates/`)

```
templates/
├── .github/
│   ├── workflows/ci.yml            # gate de PR bloqueante (adapte os checks à sua stack)
│   ├── workflows/ci-docs-noop.yml  # companheiro do paths-ignore (required check nunca trava)
│   ├── workflows/audit.yml         # npm audit mensal → abre/atualiza issue
│   ├── workflows/security.yml      # gitleaks CLI (free, bloqueante) — secrets no histórico
│   ├── workflows/preview-smoke.yml # valida que o preview de deploy responde (via check_run)
│   ├── workflows/close-sub-issues.yml # cascata: pai fechada → fecha sub-issues (cross-repo)
│   └── dependabot.yml              # semanal, majors excluídos, minor+patch agrupados
├── .claude/
│   ├── settings.json               # hooks + plugins versionados (guardrails de time)
│   ├── hooks/
│   │   ├── block-dangerous-git.sh  # PreToolUse: bloqueia git destrutivo
│   │   └── eslint-fix-edited.sh    # PostToolUse: auto-fix só no arquivo editado
│   └── skills/routing-work/        # skill de roteamento por tiers (copiável; ver ADAPTING.md)
├── .husky/
│   └── pre-commit                  # disciplina de branch no git — vale p/ humano e agente
├── .mcp.json                       # tracker plugado no agente: MCP do Jira em Docker, creds via .env
├── scripts/
│   ├── skills-install.mjs          # restaura skills do lock (postinstall seguro)
│   ├── jira-attach.sh              # anexa evidência a issue do Jira via REST
│   ├── diff-coverage.mjs           # cobertura nas linhas novas do PR (doc 14)
│   └── test-guardrails.sh          # canário do hook: must-block/must-pass (doc 11)
└── .npmrc                          # save-exact=true
```

## Checklist de guardrails

**[`CHECKLIST.md`](CHECKLIST.md)** — lista checável de guardrails sugeridos, com verificação objetiva e ponteiro pro doc/template de cada item. Serve para os dois sentidos: auditar um projeto existente (o que falta?) e implementar do zero (em que ordem?). Copie para o projeto-alvo ou cole numa issue de tracking.

### Usando com um agente de IA

Esse fluxo está empacotado como skill em [`.claude/skills/applying-guardrails/`](.claude/skills/applying-guardrails/SKILL.md): auditar (CHECKLIST preenchido com evidência) → decisão humana (itens ⚠️/custo, variante de push, conteúdo do `CLAUDE.md`) → implementar só o aprovado, por PR. Instalação no [quickstart](#comece-em-60-segundos).

Sem a skill, o mesmo contrato vale como prompt — aponte o agente para cá neste formato:

> Use `goul4rt/metodologias-desenvolvimento-ia` como referência. Rode o `CHECKLIST.md` contra o projeto `<alvo>`: para cada item, verifique com o comando/observação indicado e marque ✅/❌. Para cada ❌, proponha a implementação a partir do template referenciado, adaptando ao stack do projeto (os docs explicam o porquê de cada decisão — siga-os, não só copie o arquivo). Itens marcados ⚠️ ou que envolvem custo ([doc 09](docs/09-custos.md)) exigem minha decisão antes de implementar. Entregue: o checklist preenchido com evidência por item + os PRs/diffs propostos, em ordem de impacto.

Regras para o agente que vier por aqui: **verifique, não presuma** (cada item tem verificação objetiva — rode-a); **adapte, não copie cego** (os placeholders `⟨...⟩` e os `ADAPTING.md` dizem o que muda por projeto); **custo é decisão humana** (nada de serviço pago sem aprovação explícita — [doc 09](docs/09-custos.md)); **gap consciente se registra**, não se esconde.

## Como adotar em um repositório novo

1. **Contexto**: escreva um `CLAUDE.md` enxuto com regras objetivas ([doc 01](docs/01-contexto-do-projeto.md)).
2. **Guardrails**: copie `templates/.claude/` e versione no repo ([doc 04](docs/04-guardrails-do-agente.md)) — junto do canário que prova que eles funcionam ([doc 11](docs/11-teste-o-guardrail.md)).
3. **Gate**: adapte `templates/.github/workflows/ci.yml` à sua stack — e **zere a dívida antes de ligar o bloqueio** ([doc 02](docs/02-gate-de-ci.md)).
4. **Supply chain**: `.npmrc` com `save-exact`, pins exatos, `dependabot.yml` e `audit.yml` ([doc 03](docs/03-supply-chain.md)).
5. **Branch protection**: exija o check `ci` e bloqueie push direto na branch principal — sem isso o gate não trava nada (passo manual, precisa de admin).
6. **Fluxo**: crie um comando `/task` adaptado ao seu tracker ([doc 06](docs/06-fluxo-de-task.md)).

## Licença

[MIT](LICENSE) — copie, adapte e use; atribuição é bem-vinda.
