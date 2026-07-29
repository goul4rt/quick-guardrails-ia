# 02 — Gate de CI: 100% bloqueante ou nada

Um gate de CI só cumpre o papel — segurar regressão de código escrito por humano **ou por agente** — se todos os checks travarem o merge. Check informativo é decoração: com o tempo, todo mundo (agente incluído) aprende a ignorar o vermelho.

Template pronto: [`templates/.github/workflows/ci.yml`](../templates/.github/workflows/ci.yml)

## A precondição: zerar a dívida no mesmo PR

O motivo de gates nascerem não-bloqueantes é dívida existente: ninguém liga `eslint` como required com 213 errors na base. A prática que funcionou ([PR #123](https://github.com/Instivo/instivo-pesquisador-app/pull/123)):

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

## Branch protection: o passo que ninguém automatiza

O workflow sozinho **não trava merge nenhum**. É preciso (manual, admin):

1. Ruleset/branch protection na branch principal exigindo o check `ci`.
2. Bloqueio de push direto.

Sem isso, o gate é opcional na prática. O PR #123 listou isso como critério de aceitação explícito — é parte da entrega, não um detalhe.

> ⚠️ **Custo da enforcement**: branch protection em repo **privado** é recurso **pago** (GitHub Pro para conta pessoal, Team para organização). Em repo público, qualquer plano tem. Num privado sem plano pago, o gate roda mas não trava merge — decida conscientemente o que fazer com isso ([doc 09](09-custos.md)).

## A armadilha do `paths-ignore` + required check

Otimização natural: PR só de docs não precisa rodar o gate pesado. Mas há uma pegadinha do GitHub Actions ([PR #131](https://github.com/Instivo/instivo-pesquisador-app/pull/131)):

> Se `ci` é required e o workflow é pulado por `paths-ignore`, o check fica **pending para sempre** — e trava PRs só-de-docs indefinidamente.

A solução é um **workflow companheiro no-op** ([`ci-docs-noop.yml`](../templates/.github/workflows/ci-docs-noop.yml)) com o **mesmo nome de job** (`ci`), disparando no caso inverso (`paths` = só docs) e reportando sucesso na hora:

| Mudança | `ci.yml` (gate real) | `ci-docs-noop.yml` | check `ci` |
|---|---|---|---|
| só docs | pulado | roda, passa | ✅ |
| tem código | roda os checks | pulado | ✅ (ou ❌ se falhar) |
| docs + código | roda | roda, passa | ✅ (o real decide) |

O nome de job idêntico é **de propósito**: é o que o branch protection exige. Os dois filtros (`paths-ignore` de um, `paths` do outro) precisam ser **espelhos exatos** — se divergirem, volta o estado pending.

> No caso de origem esse PR acabou fechado sem merge (o racional não ficou registrado no PR). A lição (required check + skip = pending eterno) vale independentemente da adoção — e o custo recorrente de manter dois filtros espelhados é um argumento legítimo contra, se o tráfego de PRs só-de-docs for baixo. Ver [doc 07](07-licoes-aprendidas.md).

**Fonte**: PRs [#123](https://github.com/Instivo/instivo-pesquisador-app/pull/123) e [#131](https://github.com/Instivo/instivo-pesquisador-app/pull/131).
