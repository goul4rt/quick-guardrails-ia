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
- [ ] Válvulas de escape nomeadas com justificativa obrigatória (`# noqa`/`eslint-disable`/`@ts-expect-error` exigem comentário) + cláusula anti-cosmética por gate
  - *Verificar*: lint reprova supressão sem comentário; o contrato manda repensar a causa, não reescrever até o gate calar
- [ ] **Regra de STOP** para cada operação em que o "fix" sugerido pela ferramenta é catástrofe — [doc 10](docs/10-guardrails-alem-do-ci.md)
  - *Verificar*: sintoma exato + PARE + caminho certo + proibição do atalho

## 2. Guardrails do harness — [doc 04](docs/04-guardrails-do-agente.md)

- [ ] `.claude/settings.json` **versionado no repo** (guardrail de time, não config pessoal)
- [ ] Hook `PreToolUse` bloqueando git destrutivo — [template](templates/.claude/hooks/block-dangerous-git.sh)
  - *Verificar*: `echo '{"tool_input":{"command":"git push --force"}}' | .claude/hooks/block-dangerous-git.sh` → exit 2
- [ ] Variante de push decidida conscientemente (bloquear todo push × só forçado) e registrada no hook
- [ ] `(se aplica)` Hook `PostToolUse` de auto-fix no arquivo editado — [template](templates/.claude/hooks/eslint-fix-edited.sh)
  - *Verificar*: rápido (1 arquivo), nunca bloqueia (`exit 0`), silencioso, degrada bem
- [ ] Hooks de **git** (husky) com disciplina de branch — valem para humano E agente — [template](templates/.husky/pre-commit)
  - *Verificar*: commit em branch de integração é bloqueado; rebase/merge em andamento passa sem erro
- [ ] **Canário por gate**: casos must-block e must-pass versionados, rodando no CI — [template](templates/scripts/test-guardrails.sh) / [doc 11](docs/11-teste-o-guardrail.md)
  - *Verificar*: sabotar o hook de propósito (remover uma regra) → canário fica vermelho; restaurar → verde

## 3. Gate de CI — [doc 02](docs/02-gate-de-ci.md)

- [ ] Workflow de gate rodando em **todo PR** + push na mainline — [template](templates/.github/workflows/ci.yml)
- [ ] **Todos os checks bloqueantes** — nenhum check informativo/warning-only no gate
- [ ] Dívida zerada **antes** de ligar o bloqueio (0 errors de lint/types; suites quebradas por design em ignore explícito)
  - *Verificar*: os comandos do gate saem com exit 0 na mainline
- [ ] Checks em ordem barato → caro; `timeout-minutes`; `permissions: contents: read`; concurrency cancelando só em PR
- [ ] Nenhum exit code engolido e nenhum veredito cacheado
  - *Verificar*: todo step multi-comando com pipe tem `set -o pipefail` (ou lê `PIPESTATUS`); nenhum `actions/cache` cobre resultado de checagem
- [ ] Mudança em `.github/workflows/` só em PR dedicado (nunca de carona em refactor); steps que executam o gate têm comentário-sentinela
  - *Verificar*: `git log --oneline -- .github/workflows/` mostra apenas commits cujo assunto é CI/workflow
- [ ] **Branch protection exigindo o check + bloqueio de push direto** (⚠️ pago em repo privado — [doc 09](docs/09-custos.md))
  - *Verificar*: merge com check vermelho é impossível; OU a ausência é decisão registrada ("gate informativo, disciplina social")
- [ ] `(se aplica)` `paths-ignore` de docs acompanhado do workflow no-op espelhado — [template](templates/.github/workflows/ci-docs-noop.yml)
  - *Verificar*: os filtros dos dois workflows são espelhos exatos
- [ ] `(se aplica, plataforma builda preview de PR)` Smoke test do preview disparado por `check_run`, validando identidade do check (`app.id`) — [template](templates/.github/workflows/preview-smoke.yml)
  - *Verificar*: PR com preview quebrado (5xx) fica com o check de smoke vermelho
- [ ] Workflows sem superfície de ataque: `pull_request` (não `_target`), input de usuário via `env:` (nunca interpolado em `run:`), auto-aprovação de PR por Actions desligada — [doc 02](docs/02-gate-de-ci.md)
  - *Verificar*: `grep -rn 'pull_request_target' .github/` vazio; nenhum `${{ github.event.*.title/body/ref }}` dentro de `run:`
- [ ] Cobertura medida **no código novo do PR**, não no repo inteiro — [template](templates/scripts/diff-coverage.mjs) / [doc 14](docs/14-forca-de-teste.md)
  - *Verificar*: PR com função nova sem teste fica vermelho; piso nunca reduz
- [ ] `(se aplica, módulos com lógica de autoria IA)` Mutation testing: baseline registrado + incremental no diff do PR — [doc 14](docs/14-forca-de-teste.md)
  - *Verificar*: sabotar um branch de propósito (`>` → `>=`) → algum teste fica vermelho; score dos módulos quentes é conhecido
- [ ] `(se aplica, lógica pura/parsers/dinheiro)` Testes de propriedade complementando os de exemplo — [doc 14](docs/14-forca-de-teste.md)

## 4. Supply chain — [doc 03](docs/03-supply-chain.md)

- [ ] Deps diretas pinadas na versão exata + `save-exact` no `.npmrc` — [template](templates/.npmrc)
  - *Verificar*: nenhum `^`/`~` no `package.json`
- [ ] Dependabot semanal: patch/minor agrupados, **majors excluídos** — [template](templates/.github/dependabot.yml)
- [ ] Actions pinadas por **SHA de 40 chars** com a versão em comentário (tag é mutável) — [doc 03](docs/03-supply-chain.md)
  - *Verificar*: `grep -rE 'uses: .+@(v[0-9]|main|master)' .github/` não retorna nada
- [ ] Auditoria periódica não-bloqueante que abre/atualiza issue — [template](templates/.github/workflows/audit.yml)
- [ ] Lockfile em sync com o manifest
  - *Verificar*: `npm ci --dry-run` passa
- [ ] Política de correção registrada: nunca `audit fix --force`; validar contra baseline; documentar o que ficou de fora e por quê

## 5. Segurança do código — [doc 08](docs/08-seguranca-no-gate.md)

- [ ] Scan de secrets **determinístico e bloqueante** no histórico do PR — [template](templates/.github/workflows/security.yml)
  - *Verificar*: commitar um secret de teste em branch → check falha
- [ ] Exceções só via `.gitleaksignore` com justificativa no commit — nunca desligando o job
- [ ] Review semântico de segurança **local e dentro da assinatura** (ex.: `/security-review`) antes de PR sensível — nada de serviço por token no pipeline ([doc 09](docs/09-custos.md))
- [ ] Review de diff de autoria IA segue o checklist específico (dependência existe? API existe? duplica abstração? erro engolido? resolve o problema pedido?) — [doc 08](docs/08-seguranca-no-gate.md)
- [ ] Nenhum secret de produção alcançável pelo gate de PR
  - *Verificar*: workflows de PR só usam `permissions: contents: read` e nenhum secret além dos do próprio gate

## 6. Skills e processo — [docs 05](docs/05-skills-versionadas.md), [06](docs/06-fluxo-de-task.md), [10](docs/10-guardrails-alem-do-ci.md)

- [ ] `(se aplica)` Skills externas fixadas por hash em lockfile, restauradas por script — [template](templates/scripts/skills-install.mjs)
  - *Verificar*: clone limpo + install restaura; postinstall pulado em CI e best-effort offline
- [ ] Skill de **roteamento por tiers** adaptada ao projeto — [template + guia](templates/.claude/skills/routing-work/)
  - *Verificar*: critérios de tier observáveis; desempate T2/T3 presente; "verde" honesto por repo
- [ ] `(se aplica, 2+ repos)` **Dono do contrato** definido; spec-pai sempre nele; ordem contrato → provedor → consumidor
- [ ] `(se aplica)` Fluxo de task com **evidência por critério de aceite** e veredito honesto (PASSOU/FALHOU) — [doc 06](docs/06-fluxo-de-task.md)
- [ ] `(se aplica, tracker externo)` MCP do tracker **versionado no repo** (`.mcp.json`), servidor em Docker, credenciais lidas do `.env` no launch — [template](templates/.mcp.json)
  - *Verificar*: nenhum segredo no `.mcp.json` commitado; clone limpo + `.env` preenchido = tracker plugado
- [ ] `(se aplica, tracker com sub-issues)` Cascata de fechamento automatizada — [template](templates/.github/workflows/close-sub-issues.yml)

## 7. Meta — [docs 07](docs/07-licoes-aprendidas.md), [09](docs/09-custos.md)

- [ ] Custos conferidos para o **seu** cenário (público/privado × pessoal/org) — tabela do [doc 09](docs/09-custos.md)
- [ ] Nada por token / serviço externo obrigatório no caminho crítico do pipeline
- [ ] Exceções de convenção **documentadas no PR** que as comete, não escondidas
- [ ] Limites e capes explícitos — nenhum truncamento silencioso em scan/automação
- [ ] Regra de promoção ativa: guardrail de memória que falhou 2× sobe de nível (hook, contrato ou automação)

---

**Pontuação honesta**: não há nota mínima — há gaps conscientes e gaps invisíveis. O objetivo do checklist é converter os invisíveis em conscientes; um item aberto **com decisão registrada** vale mais que um item marcado sem verificação.
