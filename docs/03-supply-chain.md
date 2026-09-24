# 03. Supply chain: upgrade é PR explícito, nunca efeito colateral

Com um agente de IA rodando `npm install` dezenas de vezes por dia, dependência flutuante vira vetor duplo: supply-chain attack e drift silencioso de comportamento. A política inteira cabe numa frase: **nenhuma resolução de dependência muda sem passar pelo gate como PR explícito.**

Templates: [`.npmrc`](../templates/.npmrc) · [`dependabot.yml`](../templates/.github/dependabot.yml) · [`audit.yml`](../templates/.github/workflows/audit.yml)

## As quatro peças

### 1. Pins exatos + `save-exact`

Todas as deps diretas pinadas na **versão exata já instalada** (extraída do lockfile, para que nenhuma resolução mude no ato do pin) + `.npmrc` com `save-exact=true` para que todo `npm install <pkg>` futuro já pine.

Resultado: `^`/`~` deixam de existir. Um `npm install` de rotina nunca puxa versão nova por baixo.

O mesmo princípio vale para **GitHub Actions**: `uses: actions/checkout@v7` é pin de *tag*, e tag é mutável (quem controla o repo da action pode reapontá-la; foi o vetor do ataque ao `tj-actions/changed-files` em 2025). A única referência imutável é o **SHA de 40 chars**, com a versão em comentário para leitura humana (`uses: actions/checkout@3d3c42e5... # v7`). Os templates deste repo vêm pinados assim; o ecossistema `github-actions` do Dependabot (peça 2) propõe os bumps mantendo o formato.

### 2. Dependabot com majors excluídos, em modo escolhido

Bot que abre PR toda semana vira ruído, e ruído vira PR fechado sem ler. Por isso o [template](../templates/.github/dependabot.yml) é **mensal e agrupado**, e o nível de ruído é uma decisão do dono do repo, registrada na primeira linha do próprio `dependabot.yml` (modo, data, motivo):

| Modo | PRs que chegam | Quando |
|---|---|---|
| **agrupado** (padrão) | 1 de actions + 1 de npm por mês, mais os de segurança | Repo com gate de CI confiável: o PR mensal passa ou falha sozinho |
| **só-segurança** | Só security updates (`open-pull-requests-limit: 0` desliga os de versão) | Repo pouco mexido, ou time sem banda para bump de rotina. Versão velha vira dívida consciente, não esquecida |

Sem Dependabot nenhum não entra na tabela: aí ninguém vê CVE em dep transitiva até o audit mensal (peça 3).

O que vale nos dois modos:

- **Majors excluídos** (`ignore: version-update:semver-major`): major de lib nativa (React Native etc.) quebra build e merece PR humano com teste de verdade, não bot.
- **Tudo agrupado**: patch/minor num PR, actions num PR e as advisories da semana num PR (`applies-to: security-updates`).
- **`cooldown` de 7 dias**: versão recém-publicada espera uma semana antes de virar PR. Release maliciosa costuma ser removida nesse prazo, e o cooldown não atrasa security update.
- Actions dos workflows também cobertas (ecosystem `github-actions`).
- Security updates dependem do toggle do repo (Settings → Code security → Dependabot security updates), não do arquivo. Confira que está ligado.

### 3. Auditoria mensal não-bloqueante

`npm audit --audit-level=high` mensal ([template](../templates/.github/workflows/audit.yml)) que **não trava nada**: se achar high/critical, **abre uma issue** (ou comenta na existente, sem duplicar) com o relatório e a instrução de triagem. Auditar direto do lockfile, sem instalar `node_modules`.

Por que não bloquear? Vulnerabilidade nova em dep transitiva não é culpa do PR aberto às 14h de terça. Bloqueio geraria bypass cultural; issue gera triagem.

### 4. `npm audit fix` disciplinado

Quando a triagem decide corrigir (entrega E2 do estudo de caso, 32 → 13 vulnerabilidades):

- **Nunca `--force`.** No caso real, o `--force` teria instalado um *downgrade* destrutivo de major (`aws-sdk` 2.x → 1.x). O fix fica dentro dos ranges; deps diretas seguem pinadas.
- **Validar contra baseline, não contra zero**: a suíte tinha falhas pré-existentes; o critério foi "resultado **idêntico** ao baseline com o lock antigo" (mesmos passed/failed), não "tudo verde".
- **Documentar o que ficou de fora e por quê**: as 13 moderadas restantes exigiam breaking change, listadas no PR com o caminho de resolução de cada uma (upgrade de RN futuro, etc.). Dívida visível.
- **Roteiro de QA proporcional ao risco**: mudança só de lockfile pede smoke test dos fluxos críticos, sem regressão funcional esperada.

## Quando o gate morde: lockfile drift

Dias depois do pin, o `npm ci` da mainline quebrou com EUSAGE (entrega E4): commits recentes mudaram a resolução de deps (uma ferramenta pinada trocou de dependência interna), mas o lock não foi regenerado.

Leituras corretas do incidente:

1. **Não é bug do workflow.** `npm ci` *deve* falhar com lock dessincronizado; o gate pegou um problema real que antes passaria despercebido.
2. **Fix mínimo**: `npm install --package-lock-only` regenera só o lock, `package.json` intocado, nenhuma dep de app alterada.
3. **Verificação objetiva antes do merge**: `npm ci --dry-run` voltando a passar.

## A quinta peça (opcional): drift declarado × importado, e código morto

Pins, Dependabot e audit atacam **versão e CVE**, e nenhum deles vê duas derivas que agente de IA produz com frequência: pacote **importado sem estar declarado** (funciona por hoisting até parar de funcionar) ou **declarado sem uso** (superfície de ataque e de audit à toa), e **código órfão**, quando o agente gera módulos/exports que nada chama e ninguém revisa o que ninguém importa. Ferramentas OSS cobrem os dois num check só (`knip` em TS; `deptry` + `vulture` em Python). Se adotar, a regra do [doc 02](02-gate-de-ci.md) vale: zere o backlog no PR que liga o check, e bloqueante ou nada.

Anti-padrão observado num template público (jul/2026), para contraste: **lockfile no `.gitignore`** com ranges `>=`. Cada install do CI resolve versões novas (um `>=1.19` instalou o major `2.3`), e o audit escaneia um alvo que muda sozinho. É a negação das quatro peças de uma vez.

## Limite de escopo: escalar o que não é seu

Durante o trabalho de E1 apareceu um problema de arquitetura fora do escopo (secret de cloud embutido no binário pelo pipeline de release, extraível por decompilação). A resposta certa não foi "aproveitar e corrigir" nem ignorar: foi **registrar no PR como pendência conhecida e escalar à gestão**. Agente (e humano) disciplinado não expande escopo silenciosamente em área sensível.

**Fonte**: entregas E1, E2 e E4 do estudo de caso ([doc 07](07-licoes-aprendidas.md)).
