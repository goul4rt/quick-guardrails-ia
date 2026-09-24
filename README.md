<p align="center">
  <img src="docs/assets/banner-v3.png" alt="Gate de CI bloqueando merge com git push --force: o guardrail responde 'não vai assim não'" width="900">
</p>

<div align="center">

# Guardrails para desenvolvimento com IA

Guardrails que não dependem do agente obedecer: gate de CI que segura o merge, hook que barra o comando destrutivo antes de rodar, dependência pinada e task que só fecha com evidência. Tudo com ferramenta gratuita.

[![ci](https://github.com/goul4rt/quick-guardrails-ia/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/goul4rt/quick-guardrails-ia/actions/workflows/ci.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![last commit](https://img.shields.io/github/last-commit/goul4rt/quick-guardrails-ia)](https://github.com/goul4rt/quick-guardrails-ia/commits/master)

</div>

Pedir no prompt que o agente não faça algo funciona até o dia em que não funciona. Um hook ou um gate de CI funciona sempre. Este repositório reúne os guardrails, os docs que explicam cada decisão e os arquivos prontos para copiar para desenvolver com agentes de IA (Claude Code) sem contar com a obediência do modelo, usando só ferramenta OSS e recurso gratuito. A única coisa paga que ele assume é a assinatura do Claude Code que você já tem; o que exige serviço pago ou cobrança por token fica fora dos templates ([doc 09](docs/09-custos.md)).

O material vem de três codebases em produção (um app React Native, um painel Next.js e um bot em Node) onde agentes de IA passaram a trabalhar sob gate de CI, dependência pinada, hook de git e task fechada com evidência. Os números e os erros do [doc 07](docs/07-licoes-aprendidas.md) são desses projetos; só os nomes internos foram trocados. O repo também usa os próprios templates: o CI daqui roda o canário dos hooks e confere que nenhum doc aponta para arquivo que não existe.

## Por onde começar

### Auditar um repo que já existe

Instale a skill como plugin do Claude Code. Ela impõe o fluxo certo em qualquer repo:

```text
/plugin marketplace add goul4rt/quick-guardrails-ia
/plugin install guardrails@metodologias
# em qualquer repo: "aplique os guardrails" / "rode o checklist"
```

Sem plugin, o mesmo efeito vem de um clone com symlink (`ln -s <este-repo>/.claude/skills/applying-guardrails ~/.claude/skills/`), ou só do prompt da seção [Usando com um agente de IA](#usando-com-um-agente-de-ia).

### Adotar do zero

Siga os 7 passos de [Como adotar em um repositório novo](#como-adotar-em-um-repositório-novo).

### Só um arquivo

Tudo em [`templates/`](templates/) é copiável, e cada arquivo aponta o doc que explica o porquê de cada decisão.

## O que muda na prática

Teste real, registrado quando a skill foi criada: mesmo modelo, mesmo pedido (*"aplique os guardrails neste repo"*), num projeto Node recém-criado.

| Sem o guideline | Com a skill `applying-guardrails` |
|---|---|
| Implementou 15 arquivos de uma vez, sem perguntar nada | Auditou primeiro: CHECKLIST preenchido ✅/❌/n-a, com evidência (comando + resultado) por item |
| Inventou um `CLAUDE.md` inteiro (convenções de branch, regras de STOP) para um projeto que não conhece | Propôs só o esqueleto e listou as perguntas que apenas o dono do projeto responde |
| Commitou e mergeou direto na `main` | Não tocou em um arquivo sequer antes da aprovação |
| Decidiu sozinho itens com custo e trade-off | Parou no gate de decisão humana: variante de push, branch protection, autorização de install |

Mesmo modelo nos dois casos. O que mudou foi o processo que a skill impõe: auditar, depois decidir com o humano, depois implementar, e cada fase entrega um artefato antes de a próxima começar.

## Princípios

1. **Gate bloqueante ou gate nenhum.** Check que não trava merge é decoração. Zere a dívida que impede o bloqueio no mesmo PR que cria o gate.
2. **Guardrail no harness, não no prompt.** O que não pode acontecer se bloqueia com um hook `PreToolUse`, que roda antes do comando, e não com uma frase no `CLAUDE.md`.
3. **Reprodutibilidade por hash.** Dependência pinada na versão exata; skill de IA fixada por hash em lockfile. Upgrade entra como PR, com o diff visível.
4. **Evidência, não afirmação.** Task só fecha com screenshot e log por critério de aceite. Se falhou, o relatório diz que falhou.
5. **Não presuma, não invente.** Sem critério de aceite, o agente pergunta; sem PR aberto, pede um; com o MCP fora do ar, avisa e para. Trade-off vai para o humano em vez de ser decidido em silêncio.
6. **Exceções são documentadas, não escondidas.** Quem foge da convenção de propósito registra a decisão e o motivo no PR.
7. **Guardrail também é código.** Sem teste, quebra em silêncio e continua verde. Cada gate tem um canário (caso mau que deve reprovar, caso bom que deve passar) rodando no CI.

## Mapa do repositório

### Guias (`docs/`)

| Doc | Conteúdo |
|---|---|
| [01. Contexto do projeto](docs/01-contexto-do-projeto.md) | `CLAUDE.md` como contrato operacional do agente: regras objetivas, gotchas, anti-patterns |
| [02. Gate de CI](docs/02-gate-de-ci.md) | Gate de PR 100% bloqueante: ordem dos checks, concurrency, e a armadilha do required check com `paths-ignore` |
| [03. Supply chain](docs/03-supply-chain.md) | Pins exatos, Dependabot, auditoria mensal, `npm audit fix` disciplinado e lockfile drift |
| [04. Guardrails do agente](docs/04-guardrails-do-agente.md) | Hooks `PreToolUse`/`PostToolUse`: bloquear git destrutivo, auto-fix de lint, limitações conhecidas |
| [05. Skills versionadas](docs/05-skills-versionadas.md) | O que o agente carrega é dependência: skills por hash (`skills-lock.json`), set mínimo de plugins e rtk no `settings.json`, MCP pinado por versão/digest |
| [06. Fluxo de task](docs/06-fluxo-de-task.md) | `/task` e `/task close`: da issue do Jira ao merge com evidência e review duplo |
| [07. Lições aprendidas](docs/07-licoes-aprendidas.md) | Estudo de caso: o que os 5 PRs ensinaram (incluindo o que não foi adotado) |
| [08. Segurança no gate](docs/08-seguranca-no-gate.md) | Scanner determinístico bloqueia, IA recomenda: gitleaks free + review local + triagem de falha |
| [09. Custos e regra de admissão](docs/09-custos.md) | Free por padrão: o que é free, o que é "free com pegadinha", o que ficou de fora e por quê |
| [10. Guardrails além do CI](docs/10-guardrails-alem-do-ci.md) | O espectro de enforcement: hooks, automação de invariante, regras de STOP, roteamento por tiers, memória |
| [11. Teste o guardrail](docs/11-teste-o-guardrail.md) | Canário por gate: must-block/must-pass no CI, porque guardrail sem teste quebra em silêncio |
| [12. Fronteira runtime](docs/12-fronteira-runtime.md) | Guardrails de dev versus de runtime de LLM: o que transferiu, e as opções OSS (com ressalvas) para quem constrói produto |
| [13. Evidências da literatura](docs/13-evidencias-da-literatura.md) | Os números públicos (Veracode, GitClear, USENIX, DORA, RCTs) que sustentam cada doc, e o que a literatura recomenda mas ficou fora por custo |
| [14. Força de teste](docs/14-forca-de-teste.md) | Cobertura mede execução, não verificação: mutation testing, property-based testing e cobertura no código novo do PR |

### Artefatos prontos (`templates/`)

```
templates/
├── .github/
│   ├── workflows/ci.yml            # gate de PR bloqueante (adapte os checks à sua stack)
│   ├── workflows/ci-docs-noop.yml  # companheiro do paths-ignore (required check nunca trava)
│   ├── workflows/audit.yml         # npm audit mensal → abre/atualiza issue
│   ├── workflows/security.yml      # gitleaks CLI (free, bloqueante): secrets no histórico
│   ├── workflows/preview-smoke.yml # valida que o preview de deploy responde (via check_run)
│   ├── workflows/close-sub-issues.yml # cascata: pai fechada → fecha sub-issues (cross-repo)
│   ├── dependabot.yml              # mensal, agrupado, majors excluídos; modo registrado no arquivo
│   └── CODEOWNERS                  # config que o agente executa só muda com revisor humano
├── .claude/
│   ├── settings.json               # hooks + plugins versionados (guardrails de time)
│   ├── hooks/
│   │   ├── block-dangerous-git.sh  # PreToolUse: bloqueia git destrutivo
│   │   └── eslint-fix-edited.sh    # PostToolUse: auto-fix só no arquivo editado
│   └── skills/routing-work/        # skill de roteamento por tiers (copiável; ver ADAPTING.md)
├── .husky/
│   └── pre-commit                  # disciplina de branch no git, vale p/ humano e agente
├── .mcp.json                       # MCPs pinados (versão exata / digest); Jira em Docker, creds via .env
├── scripts/
│   ├── skills-install.mjs          # restaura skills do lock (postinstall seguro)
│   ├── jira-attach.sh              # anexa evidência a issue do Jira via REST
│   ├── diff-coverage.mjs           # cobertura nas linhas novas do PR (doc 14)
│   └── test-guardrails.sh          # canário do hook: must-block/must-pass (doc 11)
└── .npmrc                          # save-exact=true
```

## Checklist de guardrails

[`CHECKLIST.md`](CHECKLIST.md) é a lista checável dos guardrails, com a verificação objetiva e o ponteiro para o doc e o template de cada item. Serve nos dois sentidos: auditar um projeto que existe (o que falta?) e implementar do zero (em que ordem?). Copie para o projeto-alvo ou cole numa issue de tracking.

### Usando com um agente de IA

Esse fluxo está empacotado como skill em [`.claude/skills/applying-guardrails/`](.claude/skills/applying-guardrails/SKILL.md): auditar (CHECKLIST preenchido com evidência), decidir com o humano (itens ⚠️ ou com custo, variante de push, conteúdo do `CLAUDE.md`) e implementar só o aprovado, por PR. Instalação em [Por onde começar](#por-onde-começar).

Sem a skill, o mesmo contrato vale como prompt. Cole no agente, trocando `<alvo>`:

```text
Referência: github.com/goul4rt/quick-guardrails-ia (CHECKLIST.md, docs/ e templates/).

Audite o projeto <alvo> contra o CHECKLIST.md:

1. Para cada item, rode a verificação indicada e marque ✅, ❌ ou n/a,
   com a evidência (comando rodado + resultado).
2. Entregue o checklist preenchido ANTES de tocar em qualquer arquivo.
3. Para cada ❌, proponha a implementação a partir do template citado,
   adaptada à stack do projeto. Leia o doc do item: ele explica o porquê.
4. Item ⚠️ ou com custo (doc 09) espera a minha decisão. Nada é
   implementado antes dela.
5. Ordene as propostas por impacto neste projeto, não pela ordem do checklist.
```

Quatro regras para o agente que vier por aqui:

- Rode a verificação de cada item em vez de presumir o resultado.
- Adapte o template ao projeto: os placeholders `⟨...⟩` e os `ADAPTING.md` dizem o que muda.
- Nada de serviço pago sem aprovação explícita ([doc 09](docs/09-custos.md)).
- O que ficar de fora entra registrado como gap consciente, no PR ou em issue.

## Como adotar em um repositório novo

0. Na máquina, uma vez: o rtk e os plugins do set mínimo ([doc 05](docs/05-skills-versionadas.md)). O que é por repo (plugins habilitados, hook do rtk) já vem no `templates/.claude/settings.json`.
   ```bash
   brew install rtk                          # macOS/Linux; Windows: winget install rtk-ai.rtk; outros: github.com/rtk-ai/rtk#installation
   rtk init -g
   claude plugins install mattpocock-skills
   claude plugins install ponytail@ponytail  # marketplace já declarado no settings.json
   ```
1. Escreva um `CLAUDE.md` enxuto, com regras que dá para checar num diff ([doc 01](docs/01-contexto-do-projeto.md)).
2. Copie `templates/.claude/` e versione no repo ([doc 04](docs/04-guardrails-do-agente.md)), junto do canário que prova que os hooks funcionam ([doc 11](docs/11-teste-o-guardrail.md)).
3. Adapte `templates/.github/workflows/ci.yml` à sua stack e zere a dívida antes de ligar o bloqueio ([doc 02](docs/02-gate-de-ci.md)).
4. Supply chain: `.npmrc` com `save-exact`, pins exatos, `dependabot.yml` e `audit.yml` ([doc 03](docs/03-supply-chain.md)).
5. Branch protection: exija o check `ci` e bloqueie push direto na branch principal. Sem isso o gate não trava nada (passo manual, precisa de admin).
6. Crie um comando `/task` adaptado ao seu tracker ([doc 06](docs/06-fluxo-de-task.md)).

## Licença

[MIT](LICENSE): copie, adapte e use; atribuição é bem-vinda.
