# 03 — Supply chain: upgrade é PR explícito, nunca efeito colateral

Com um agente de IA rodando `npm install` dezenas de vezes por dia, dependência flutuante vira vetor duplo: supply-chain attack e drift silencioso de comportamento. A política inteira cabe numa frase: **nenhuma resolução de dependência muda sem passar pelo gate como PR explícito.**

Templates: [`.npmrc`](../templates/.npmrc) · [`dependabot.yml`](../templates/.github/dependabot.yml) · [`audit.yml`](../templates/.github/workflows/audit.yml)

## As quatro peças

### 1. Pins exatos + `save-exact`

Todas as deps diretas pinadas na **versão exata já instalada** (extraída do lockfile — nenhuma resolução muda no ato do pin) + `.npmrc` com `save-exact=true` para que todo `npm install <pkg>` futuro já pine.

Resultado: `^`/`~` deixam de existir. Um `npm install` de rotina nunca puxa versão nova por baixo.

### 2. Dependabot com majors excluídos

Semanal, com duas decisões deliberadas ([template](../templates/.github/dependabot.yml)):

- **Patch/minor agrupados** num PR só (`groups`) — menos ruído de review.
- **Majors excluídos** (`ignore: version-update:semver-major`) — major de lib nativa (React Native etc.) quebra build e merece PR humano com teste de verdade, não bot.
- Actions dos workflows também cobertas (ecosystem `github-actions`).

### 3. Auditoria mensal não-bloqueante

`npm audit --audit-level=high` mensal ([template](../templates/.github/workflows/audit.yml)) que **não trava nada** — se achar high/critical, **abre uma issue** (ou comenta na existente, sem duplicar) com o relatório e a instrução de triagem. Auditar direto do lockfile, sem instalar `node_modules`.

Por que não bloquear? Vulnerabilidade nova em dep transitiva não é culpa do PR aberto às 14h de terça. Bloqueio geraria bypass cultural; issue gera triagem.

### 4. `npm audit fix` disciplinado

Quando a triagem decide corrigir ([PR #125](https://github.com/Instivo/instivo-pesquisador-app/pull/125), 32 → 13 vulnerabilidades):

- **Nunca `--force`** — no caso real, o `--force` teria instalado um *downgrade* destrutivo de major (`aws-sdk` 2.x → 1.x). O fix fica dentro dos ranges; deps diretas seguem pinadas.
- **Validar contra baseline, não contra zero**: a suíte tinha falhas pré-existentes; o critério foi "resultado **idêntico** ao baseline com o lock antigo" (mesmos passed/failed), não "tudo verde".
- **Documentar o que ficou de fora e por quê**: as 13 moderadas restantes exigiam breaking change — listadas no PR com o caminho de resolução de cada uma (upgrade de RN futuro, etc.). Dívida visível.
- **Roteiro de QA proporcional ao risco**: mudança só de lockfile → smoke test dos fluxos críticos, sem regressão funcional esperada.

## Quando o gate morde: lockfile drift

Dias depois do pin, o `npm ci` da mainline quebrou com EUSAGE ([PR #130](https://github.com/Instivo/instivo-pesquisador-app/pull/130)): commits recentes mudaram a resolução de deps (uma ferramenta pinada trocou de dependência interna), mas o lock não foi regenerado.

Leituras corretas do incidente:

1. **Não é bug do workflow.** `npm ci` *deve* falhar com lock dessincronizado — o gate pegou um problema real que antes passaria despercebido.
2. **Fix mínimo**: `npm install --package-lock-only` — regenera só o lock, `package.json` intocado, nenhuma dep de app alterada.
3. **Verificação objetiva antes do merge**: `npm ci --dry-run` voltando a passar.

## Limite de escopo: escalar o que não é seu

Durante o trabalho do PR #123 apareceu um problema de arquitetura fora do escopo (secret de cloud embutido no APK pelo pipeline de release — extraível por decompilação). A resposta certa não foi "aproveitar e corrigir" nem ignorar: foi **registrar no PR como pendência conhecida e escalar à gestão**. Agente (e humano) disciplinado não expande escopo silenciosamente em área sensível.

**Fonte**: PRs [#123](https://github.com/Instivo/instivo-pesquisador-app/pull/123), [#125](https://github.com/Instivo/instivo-pesquisador-app/pull/125) e [#130](https://github.com/Instivo/instivo-pesquisador-app/pull/130).
