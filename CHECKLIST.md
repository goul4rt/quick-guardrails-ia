# Checklist de guardrails

Lista checável para auditar um projeto contra este guideline — ou guiar a implementação do zero. Cada item tem **verificação objetiva** (como saber se está feito) e o **doc/template** que o implementa.

**Como usar**: copie este arquivo para o projeto-alvo (ou cole numa issue de tracking) e marque o que já existe. Item não marcado = gap; a coluna de referência diz onde está a implementação pronta. Itens `(se aplica)` só contam quando a condição vale.

**Com um agente de IA**: aponte o agente para este repositório e peça para rodar este checklist contra o projeto-alvo — instruções no [README](README.md#usando-com-um-agente-de-ia).

---

## 1. Contexto do agente — [doc 01](docs/01-contexto-do-projeto.md)

- [ ] `CLAUDE.md` (ou equivalente) na raiz, carregado a cada sessão
  - *Verificar*: o arquivo existe e cabe no contexto sem dominar (guia, não enciclopédia)
- [ ] Seção de postura no topo: não presuma, exponha trade-offs, pergunte na ambiguidade
- [ ] Regras objetivas e checáveis num diff (com exemplos ✅/❌), não prosa genérica
  - *Verificar*: para cada regra, um reviewer consegue dizer objetivamente se um diff a viola
- [ ] Gotchas registrados **com o porquê** de cada um
- [ ] Tabela de anti-patterns (Não faça | Porquê)
- [ ] **Regra de STOP** para cada operação em que o "fix" sugerido pela ferramenta é catástrofe — [doc 10](docs/10-guardrails-alem-do-ci.md)
  - *Verificar*: sintoma exato + PARE + caminho certo + proibição do atalho

## 2. Guardrails do harness — [doc 04](docs/04-guardrails-do-agente.md)

- [ ] `.claude/settings.json` **versionado no repo** (guardrail de time, não config pessoal)
- [ ] Hook `PreToolUse` bloqueando git destrutivo — [template](templates/.claude/hooks/block-dangerous-git.sh)
  - *Verificar*: `echo '{"tool_input":{"command":"git push --force"}}' | .claude/hooks/block-dangerous-git.sh` → exit 2
- [ ] Variante de push decidida conscientemente (bloquear todo push × só forçado) e registrada no hook
- [ ] `(se aplica)` Hook `PostToolUse` de auto-fix no arquivo editado — [template](templates/.claude/hooks/eslint-fix-edited.sh)
  - *Verificar*: rápido (1 arquivo), nunca bloqueia (`exit 0`), silencioso, degrada bem

## 3. Gate de CI — [doc 02](docs/02-gate-de-ci.md)

- [ ] Workflow de gate rodando em **todo PR** + push na mainline — [template](templates/.github/workflows/ci.yml)
- [ ] **Todos os checks bloqueantes** — nenhum check informativo/warning-only no gate
- [ ] Dívida zerada **antes** de ligar o bloqueio (0 errors de lint/types; suites quebradas por design em ignore explícito)
  - *Verificar*: os comandos do gate saem com exit 0 na mainline
- [ ] Checks em ordem barato → caro; `timeout-minutes`; `permissions: contents: read`; concurrency cancelando só em PR
- [ ] **Branch protection exigindo o check + bloqueio de push direto** (⚠️ pago em repo privado — [doc 09](docs/09-custos.md))
  - *Verificar*: merge com check vermelho é impossível; OU a ausência é decisão registrada ("gate informativo, disciplina social")
- [ ] `(se aplica)` `paths-ignore` de docs acompanhado do workflow no-op espelhado — [template](templates/.github/workflows/ci-docs-noop.yml)
  - *Verificar*: os filtros dos dois workflows são espelhos exatos

## 4. Supply chain — [doc 03](docs/03-supply-chain.md)

- [ ] Deps diretas pinadas na versão exata + `save-exact` no `.npmrc` — [template](templates/.npmrc)
  - *Verificar*: nenhum `^`/`~` no `package.json`
- [ ] Dependabot semanal: patch/minor agrupados, **majors excluídos** — [template](templates/.github/dependabot.yml)
- [ ] Auditoria periódica não-bloqueante que abre/atualiza issue — [template](templates/.github/workflows/audit.yml)
- [ ] Lockfile em sync com o manifest
  - *Verificar*: `npm ci --dry-run` passa
- [ ] Política de correção registrada: nunca `audit fix --force`; validar contra baseline; documentar o que ficou de fora e por quê

## 5. Segurança do código — [doc 08](docs/08-seguranca-no-gate.md)

- [ ] Scan de secrets **determinístico e bloqueante** no histórico do PR — [template](templates/.github/workflows/security.yml)
  - *Verificar*: commitar um secret de teste em branch → check falha
- [ ] Exceções só via `.gitleaksignore` com justificativa no commit — nunca desligando o job
- [ ] Review semântico de segurança **local e dentro da assinatura** (ex.: `/security-review`) antes de PR sensível — nada de serviço por token no pipeline ([doc 09](docs/09-custos.md))
- [ ] Nenhum secret de produção alcançável pelo gate de PR
  - *Verificar*: workflows de PR só usam `permissions: contents: read` e nenhum secret além dos do próprio gate

## 6. Skills e processo — [docs 05](docs/05-skills-versionadas.md), [06](docs/06-fluxo-de-task.md), [10](docs/10-guardrails-alem-do-ci.md)

- [ ] `(se aplica)` Skills externas fixadas por hash em lockfile, restauradas por script — [template](templates/scripts/skills-install.mjs)
  - *Verificar*: clone limpo + install restaura; postinstall pulado em CI e best-effort offline
- [ ] Skill de **roteamento por tiers** adaptada ao projeto — [template + guia](templates/.claude/skills/routing-work/)
  - *Verificar*: critérios de tier observáveis; desempate T2/T3 presente; "verde" honesto por repo
- [ ] `(se aplica, 2+ repos)` **Dono do contrato** definido; spec-pai sempre nele; ordem contrato → provedor → consumidor
- [ ] `(se aplica)` Fluxo de task com **evidência por critério de aceite** e veredito honesto (PASSOU/FALHOU) — [doc 06](docs/06-fluxo-de-task.md)
- [ ] `(se aplica, tracker com sub-issues)` Cascata de fechamento automatizada — [template](templates/.github/workflows/close-sub-issues.yml)

## 7. Meta — [docs 07](docs/07-licoes-aprendidas.md), [09](docs/09-custos.md)

- [ ] Custos conferidos para o **seu** cenário (público/privado × pessoal/org) — tabela do [doc 09](docs/09-custos.md)
- [ ] Nada por token / serviço externo obrigatório no caminho crítico do pipeline
- [ ] Exceções de convenção **documentadas no PR** que as comete, não escondidas
- [ ] Limites e capes explícitos — nenhum truncamento silencioso em scan/automação
- [ ] Regra de promoção ativa: guardrail de memória que falhou 2× sobe de nível (hook, contrato ou automação)

---

**Pontuação honesta**: não há nota mínima — há gaps conscientes e gaps invisíveis. O objetivo do checklist é converter os invisíveis em conscientes; um item aberto **com decisão registrada** vale mais que um item marcado sem verificação.
