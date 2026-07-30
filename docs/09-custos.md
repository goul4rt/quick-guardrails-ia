# 09 — Custos e regra de admissão: free por padrão

Este repositório é um guideline formal de **0 → funcionando sem orçamento**: regras locais (hooks, configs versionadas), ferramentas OSS e recursos públicos/gratuitos. Artigos de DevSecOps costumam apresentar pipelines como se fossem de graça e a enforcement como se fosse automática — nenhuma das duas coisas é verdade por padrão. Esta página fixa a regra e dá a tabela para decidir rápido.

## A regra de admissão

1. **Todo template deste repo tem caminho 100% free.** Se uma peça só funciona pagando serviço externo, ela não entra — no máximo é citada em doc com o porquê de ter ficado de fora.
2. **A base aceita é o Claude Code por assinatura** — custo fixo que você já paga para desenvolver. Tudo que a metodologia pede do agente (hooks, skills, `/task`, reviews locais) roda dentro dela.
3. **Cobrança por token e agente/serviço externo obrigatório: evitar.** Custo variável por PR/execução escala com o uso e cria dependência externa para o pipeline sequer funcionar. O trabalho que seria do serviço pago volta para dentro da assinatura (ex.: `/security-review` local em vez de action de review por API).
4. **Free tier com rate limit nunca entra em check bloqueante** — cota estourada vira PR travado por motivo nenhum. Free tier serve para o que tolera falha silenciosa (ex.: análise pós-falha, [doc 08](08-seguranca-no-gate.md) camada 3).

> Condições verificadas em jul/2026. Planos mudam — na dúvida, confira a fonte antes de decidir.

## Tabela de decisão

### 🟢 Free de verdade (é o que este repo usa)

| Componente | O que é |
|---|---|
| `CLAUDE.md`, hooks bash, `skills-install.mjs`, `jira-attach.sh` | Regras locais, código versionado no seu repo |
| ESLint, Prettier, tsc, Jest, commitlint | OSS |
| `npm audit` + Dependabot | Nativos do npm/GitHub, qualquer plano |
| **gitleaks CLI** | MIT, sem cadastro — é o que o [`security.yml`](../templates/.github/workflows/security.yml) usa |
| Plugins `superpowers`, `ponytail`; CLI `skills` | OSS |
| Claude Code (assinatura que você já tem) | `/task`, `/security-review`, hooks, skills — sem custo adicional por uso |

### 🟡 Free com condição (a pegadinha — decida pelo SEU cenário)

| Componente | Free quando | Deixa de ser quando |
|---|---|---|
| **GitHub Actions** | Repo **público**: ilimitado | Repo **privado**: 2.000 min/mês no plano Free, depois cobra por minuto |
| **Branch protection / required checks** | Repo **público**: qualquer plano | Repo **privado**: exige **Pro** (pessoal) ou **Team** (org). **Sem isso, nenhum gate trava merge** — ver [doc 02](02-gate-de-ci.md) |
| **GitHub Models** (LLM via `GITHUB_TOKEN`) | Free tier com rate limit — ok pós-falha | Produção/bloqueante: pay-as-you-go (regra 4) |
| **Slack** (webhook de alerta) | Plano free aceita incoming webhook | — |
| **Jira Cloud** | Até 10 usuários | 11+ usuários |

### 🔴 Fora do repo (sem caminho free) — e o substituto

| Peça citada nos docs | Por que ficou de fora | Substituto free |
|---|---|---|
| `anthropics/claude-code-security-review` (action) | O action é OSS, mas consome `ANTHROPIC_API_KEY` — **custo por token a cada PR** | `/security-review` no Claude Code local, antes de abrir o PR ([doc 08](08-seguranca-no-gate.md)) |
| `gitleaks-action` v2+ em organização | Exige `GITLEAKS_LICENSE` (cadastro; licença não-MIT) | gitleaks **CLI** direto no workflow — já é o template |
| Qualquer "AI reviewer" SaaS de PR | Serviço externo obrigatório + cobrança por uso | Review local pelo agente que você já assina + gate determinístico |

Registrar o que ficou de fora **e por quê** é o mesmo padrão do [doc 03](03-supply-chain.md) (as 13 vulnerabilidades não corrigidas, documentadas): dívida e limite visíveis, não silenciosos.

### ⚪ Fora por escopo (não por custo)

Peças que a literatura recomenda ([doc 13](13-evidencias-da-literatura.md)), têm caminho free, e mesmo assim ficaram de fora — a razão é valor, não preço:

| Peça | Por que não entra |
|---|---|
| SBOM + assinatura de artefato (Syft, cosign, SLSA) | O valor é para artefato **distribuído** (pacote publicado, binário de release) — quem verifica a assinatura é o consumidor. App privado que deploya do próprio repo não tem esse consumidor. Se um dia publicar pacote/imagem, reavalie |
| DAST (scan da app rodando) | Exige ambiente deployado por PR + minutos de scan. O smoke de preview ([doc 02](02-gate-de-ci.md)) cobre o caso barato (a app sobe?); DAST de verdade é decisão de projeto, não default |
| Métrica de churn de código IA | O tooling que a mede em escala (GitClear) é pago; proxy via `git log` existe, mas sem baseline de mercado o número não diz nada. O sinal acionável equivalente: mutation score baixo em módulo de autoria IA ([doc 14](14-forca-de-teste.md)) |

## Os 2.000 minutos acabam — anatomia de um estouro real

Caso de jul/2026, conta pessoal Free com 6 repos privados ativos: **~1.800 dos 2.000 min consumidos**, pagamento da sobra falhou e o GitHub **parou de iniciar runs em todos os repos privados da conta** — todo PR novo nasce com CI vermelho em segundos, sem log, e o sintoma não diz "cota": diz "payments have failed". O estouro não veio de um repo caro; veio de quatro padrões pequenos somados:

| Padrão | Custo medido | Correção |
|---|---|---|
| **Jobs paralelos multiplicam o custo fixo** — cada job paga o próprio `npm ci` E arredonda pra cima no minuto | Gate com 3 jobs: ~7 min faturáveis/run vs ~4 do mesmo gate em série (777 min/mês) | Um job só, checks em série barato→caro (o [template](../templates/.github/workflows/ci.yml) já é assim). Latência de PR não paga a conta |
| **Revalidação de merge** — gate no PR + `push: main` re-rodando o tree que o PR acabou de aprovar | Metade dos runs do repo mais ativo era revalidação (~340 min/mês) | Trocar `push: main` por **cron diário** na main: cobre o único risco real (race de merge-order) por ~30 min/mês |
| **Runner pago dormindo** — `sleep 180` esperando deploy propagar antes de um ping | 40 runs × ~4 min, quase tudo sono (~157 min/mês) | Workflow que não é gate não precisa ser por push. Cron diário → o deploy já propagou, o sleep morre junto |
| **Piso de 1 minuto por job** — script de 5s fatura 1 min | Automação por evento (cascata de issues): dezenas de min/mês | Aceitável **se conhecido**. O perigo é o invisível: todo `on:` que dispara em evento frequente tem esse piso |

Como medir sem adivinhar: o campo `billable` do endpoint `/runs/{id}/timing` **retorna zero** para contas na plataforma nova de billing do GitHub — o que funciona é somar a duração dos jobs (`/runs/{id}/jobs`, arredondando cada um pra cima no minuto, que é como o GitHub cobra) ou `gh api /users/{user}/settings/billing/usage` (exige scope `user`). Parede ≠ faturável: um run de 3 min com 3 jobs paralelos fatura ~7.

A alavanca que zera tudo: **runner self-hosted** numa máquina que você já paga (min ilimitados em repo privado). Nunca em repo **público** — PR de fork executa código arbitrário na sua máquina.

## Regras de decisão rápidas

- **Repo público** → tudo deste repo funciona free, incluindo a enforcement (branch protection).
- **Repo privado sem plano pago** → o gate roda mas **não trava merge**. Aceite explicitamente que o gate é informativo e a disciplina é social — e registre isso — ou torne o repo público, ou pague a enforcement. Não finja que há guardrail onde não há.
- **Organização** → confira a **licença** de cada action, não só o preço (o caso gitleaks-action). CLI direto costuma ser o caminho sem fricção.
- **Vontade de IA no pipeline** → comece pelo que roda só em falha (custo zero de gate, free tier tolerável). Review semântico fica **local, dentro da assinatura**.

## Free por cortesia tem prazo

Evidência de jul/2026, do maior framework OSS de guardrails de runtime ([doc 12](12-fronteira-runtime.md)): os endpoints de inferência hospedados, lançados como "free preview", foram anunciados para desligamento em **06/08/2026** — e o registry de pacotes próprio (token-gated) do mesmo projeto foi abandonado em favor do PyPI público. O padrão: **free por cortesia do vendor é uma promoção, não uma propriedade** — expira quando a estratégia muda. O que sobrevive é o artefato que você mesmo pode hospedar e rodar (o pacote OSS, o CLI, os pesos com licença livre). Na dúvida entre dois caminhos free, escolha o que continua existindo se o vendor sumir amanhã — é o mesmo critério que já decidiu gitleaks CLI sobre gitleaks-action.

## O que os artigos não contam

O artigo de origem do [doc 08](08-seguranca-no-gate.md) afirma que "developers cannot bypass security checks because they are embedded directly into the CI/CD pipeline". **Isso é falso sem branch protection** — que ele não menciona, e que em repo privado é recurso pago. Workflow no repo ≠ enforcement: qualquer um mergeia com o check vermelho até existir uma regra exigindo o check verde. A lição generaliza: **todo tutorial de pipeline assume enforcement que ele nunca configura e custo que ele nunca declara.** Verifique os dois antes de adotar qualquer coisa — inclusive deste repositório.
