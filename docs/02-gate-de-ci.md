# 02 — Gate de CI: 100% bloqueante ou nada

Um gate de CI só cumpre o papel — segurar regressão de código escrito por humano **ou por agente** — se todos os checks travarem o merge. Check informativo é decoração: com o tempo, todo mundo (agente incluído) aprende a ignorar o vermelho.

Template pronto: [`templates/.github/workflows/ci.yml`](../templates/.github/workflows/ci.yml)

## A precondição: zerar a dívida no mesmo PR

O motivo de gates nascerem não-bloqueantes é dívida existente: ninguém liga `eslint` como required com 213 errors na base. A prática que funcionou (entrega E1 do estudo de caso — [doc 07](07-licoes-aprendidas.md)):

- **213 errors de ESLint → 0** — quase tudo escopo/config (ignores de código vendored, globals por contexto, opções de regra para idiomas legítimos da stack), não reescrita de código. As 35 ocorrências flexibilizadas foram **conferidas uma a uma**.
- **97 erros de `tsc` → 0** — correções só de tipo + remoção de código morto que os erros revelaram. Zero mudança de comportamento.
- **Jest destravado** — `transformIgnorePatterns` para deps ESM + mocks nativos; suites quebradas *por design* ficam em `testPathIgnorePatterns` **explícito** (dívida visível, não silenciosa).

O pacote inteiro num PR só: quando o gate liga, já liga bloqueante. Não existe fase "warning-only" para a equipe se acostumar a ignorar.

## Anatomia do workflow

Decisões que valem copiar (todas comentadas no template):

| Decisão | Porquê |
|---|---|
| Checks em ordem barato → caro (`commitlint → eslint → schema-check → prettier → tsc → jest`) | Falha rápida; não paga 10 min de testes para descobrir commit fora do padrão |
| `concurrency` cancela run obsoleto **só em PR** | Push novo no PR mata o run anterior (economia); push na mainline sempre roda inteiro (histórico íntegro) |
| `timeout-minutes: 15` | Step pendurado não segura o runner pelas 6h default |
| `permissions: contents: read` | Nenhum secret de produção toca o gate; PR malicioso não exfiltra nada |
| `HUSKY: 0` no install | Git hooks locais não rodam no CI (o CI *é* o hook) |
| `fetch-depth: 0` | Commitlint precisa do range completo de commits do PR |
| Resumo no `$GITHUB_STEP_SUMMARY` | Quem abre o run entende o contrato do gate sem ler o YAML |
| Gate separado do pipeline de release | O `build.yml` (release) segue intocado; gate de PR não builda APK |

## CI verde que não prova nada

Antes de bloquear merge, o check precisa **falhar quando o trabalho falha** — e há três jeitos clássicos de perder isso sem perceber (os dois primeiros flagrados num pipeline público de "AI guardrail" examinado em jul/2026, com 31 de 38 runs `success` e `BUILD FAILED` no log; o terceiro num dos três codebases de origem):

- **Exit code engolido por pipe.** `./build 2>&1 | tee build.log` reporta o status do `tee`, sempre 0. Regra: `set -o pipefail` no topo de todo step multi-comando — ou `${PIPESTATUS[0]}` **lido e usado**. No caso examinado, o exit code era capturado em `$GITHUB_OUTPUT` e nunca lido em lugar nenhum: pior que não capturar, porque parece rigor.
- **Veredito de gate cacheado.** `actions/cache` guardando o *resultado* de um scan por hash de árvore faz o step virar `skipped` — o badge verde vira o `cat` de um arquivo antigo. Cache é para dependência e artefato; veredito de checagem se recomputa sempre. Se o custo dói, reduza o escopo (diff-only), não memoize o resultado.
- **Step deletado de carona num refactor.** No bot Node do estudo de caso, um refactor de feature co-autorado por IA (dezenas de arquivos) incluiu `ci.yml | 1 deletion`: a linha que rodava a suíte de testes. O job manteve o nome "Test", continuou fazendo checkout + install + codegen e continuou **verde por ~4 meses executando zero testes** — 800+ testes fora do gate, descoberto só em auditoria. Ninguém revisa 1 linha de workflow no meio de um diff de 50 arquivos. Antídoto: **mudança em `.github/workflows/` é PR dedicado, nunca carona** — qualquer diff de workflow dentro de PR de feature é red flag automático; e o step que executa o gate leva comentário-sentinela ("não remover: já sumiu uma vez sem ninguém notar, <commit>").

O antídoto sistemático para os dois primeiros é o canário por gate — [doc 11](11-teste-o-guardrail.md). O terceiro é imune ao canário (o step deletado leva o canário junto); a defesa é a regra de PR dedicado acima.

## Branch protection: o passo que ninguém automatiza

O workflow sozinho **não trava merge nenhum**. É preciso (manual, admin):

1. Ruleset/branch protection na branch principal exigindo o check `ci`.
2. Bloqueio de push direto.

Sem isso, o gate é opcional na prática. No caso de origem isso foi listado como critério de aceitação explícito — é parte da entrega, não um detalhe.

> ⚠️ **Custo da enforcement**: branch protection em repo **privado** é recurso **pago** (GitHub Pro para conta pessoal, Team para organização). Em repo público, qualquer plano tem. Num privado sem plano pago, o gate roda mas não trava merge — decida conscientemente o que fazer com isso ([doc 09](09-custos.md)).

## A armadilha do `paths-ignore` + required check

Otimização natural: PR só de docs não precisa rodar o gate pesado. Mas há uma pegadinha do GitHub Actions (entrega E3 do estudo de caso):

> Se `ci` é required e o workflow é pulado por `paths-ignore`, o check fica **pending para sempre** — e trava PRs só-de-docs indefinidamente.

A solução é um **workflow companheiro no-op** ([`ci-docs-noop.yml`](../templates/.github/workflows/ci-docs-noop.yml)) com o **mesmo nome de job** (`ci`), disparando no caso inverso (`paths` = só docs) e reportando sucesso na hora:

| Mudança | `ci.yml` (gate real) | `ci-docs-noop.yml` | check `ci` |
|---|---|---|---|
| só docs | pulado | roda, passa | ✅ |
| tem código | roda os checks | pulado | ✅ (ou ❌ se falhar) |
| docs + código | roda | roda, passa | ✅ (o real decide) |

O nome de job idêntico é **de propósito**: é o que o branch protection exige. Os dois filtros (`paths-ignore` de um, `paths` do outro) precisam ser **espelhos exatos** — se divergirem, volta o estado pending.

> No caso de origem essa entrega acabou fechada sem merge (o racional não ficou registrado). A lição (required check + skip = pending eterno) vale independentemente da adoção — e o custo recorrente de manter dois filtros espelhados é um argumento legítimo contra, se o tráfego de PRs só-de-docs for baixo. Ver [doc 07](07-licoes-aprendidas.md).

## O gate não acaba no merge: smoke do preview

Quando a plataforma de deploy (Cloudflare Pages, Vercel, ...) builda um **preview a cada push do PR** fora do Actions, o gate de código passa — e o preview pode estar quebrado (crash de runtime, env faltando). O padrão de um caso real de painel web em produção ([template](../templates/.github/workflows/preview-smoke.yml)):

- **Dispara no `check_run` que a própria plataforma posta** ao terminar o deploy — sem polling; o job só roda quando o preview existe.
- **Valida a identidade do check** (`check_run.app.id`), não só o nome — check-run com nome forjado por outro app não dispara o smoke.
- **Falha só em 5xx/timeout** nas rotas principais — o objetivo é pegar crash de build/runtime, não validar conteúdo ou auth.
- **Fallback manual** (`workflow_dispatch` com a URL) para quando o check-run não veio.
- **Gotcha documentado**: eventos `check_run` só disparam com o workflow já presente na branch default — a mudança não se autovalida no PR que a introduz.

**Fonte**: entregas E1 e E3 do estudo de caso ([doc 07](07-licoes-aprendidas.md)) + smoke de preview de um painel web em produção.
