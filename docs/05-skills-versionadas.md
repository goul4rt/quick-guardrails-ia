# 05. Skills versionadas: `skills-lock.json` como fonte da verdade

Skills de agente (instruções que mudam como o Claude Code trabalha) vêm de repositórios de terceiros que **mudam por baixo**. Sem versionamento, dois devs do mesmo time rodam agentes com comportamentos diferentes, e um `git pull` do autor da skill muda seu fluxo sem ninguém aprovar nada. A solução é a mesma do ecossistema npm: **lockfile por hash**.

Templates: [`skills-install.mjs`](../templates/scripts/skills-install.mjs)

## O modelo: análogo ao `package-lock.json`

| Conceito npm | Equivalente de skills |
|---|---|
| `package-lock.json` | `skills-lock.json`, cada skill fixada por `source` (repo GitHub), `skillPath` e `computedHash` |
| `node_modules/` (gitignorado) | `.agents/skills/` + `.claude/skills/` (gitignorados, gerados) |
| `npm ci` | `npm run skills:install`, restaura do lock |
| `npm install <pkg>` | `npx skills add <pkg> --skill <nome>`, reescreve o lock, que aí sim é commitado |

O que vai para o git é **só o lock + o script de restore**. Upgrade de skill vira diff de hash revisável em PR, exatamente como bump de dependência.

## O restore: `scripts/skills-install.mjs`

Dois passos (o CLI `skills` restaura só o store canônico em `.agents/skills/`; os links que o Claude Code lê em `.claude/skills/` são recriados pelo script):

1. `npx skills experimental_install` baixa cada skill na revisão do hash.
2. Recria `.claude/skills/` **do zero** (sem deixar link órfão de skill removida) com symlinks relativos para `.agents/skills/`.

Decisões de engenharia que valem copiar:

- **Node, não shell**: roda onde o npm roda, inclusive Windows, onde `bash`/`ln -s` não existem por padrão.
- **Symlink com fallback para cópia**: Windows sem modo desenvolvedor não cria symlink; o script cai para `cpSync` silenciosamente. `SKILLS_COPY=1` força cópia.
- **Symlink relativo** (`../../.agents/skills/<nome>`): portável entre máquinas.

## O gancho: `postinstall` seguro

O restore roda automático no `npm install` (`postinstall` → `--if-missing`), e é aqui que mora o cuidado: um `postinstall` malcomportado quebra o install de todo mundo.

| Proteção | Porquê |
|---|---|
| Pulado em CI (`env CI`) | O gate não precisa de skills; não gasta rede nem falha à toa |
| Pulado se já instaladas | Idempotente; `npm install` de rotina não refaz nada |
| **Best-effort**: falha (offline) vira aviso + `exit 0` | `npm install` num avião não pode quebrar por causa de skill |
| Forçado (`npm run skills:install`) propaga a falha | Quando o dev pede explicitamente, erro é erro |

## Dois mecanismos convivendo

O lock vendoriza skills avulsas. **Plugins de marketplace** (skills invocadas com prefixo, ex.: `mattpocock-skills:grilling`) são outro mecanismo: declarados em `.claude/settings.json` (`enabledPlugins`), mas cada dev instala o marketplace uma vez na máquina. O `README` do projeto documenta os dois e quando cada um se aplica: o comando `/task` do projeto depende dos plugins; a reprodutibilidade bit-a-bit vem do lock.

### O set mínimo, declarado no repo

"Skills que eu sempre uso" não é memória de quem inicia o projeto: é o `enabledPlugins` do [`settings.json`](../templates/.claude/settings.json) template, versionado, que todo clone recebe. O set atual:

| Item | Onde fica | Por quê |
|---|---|---|
| `mattpocock-skills@claude-plugins-official` | `enabledPlugins` | Skills de processo (spec, tickets, triage, grilling); marketplace oficial, não precisa de `add` |
| `ponytail@ponytail` | `enabledPlugins` | Solução mínima primeiro; o marketplace se instala uma vez por máquina |
| hook `rtk hook claude` | `hooks.PreToolUse` (Bash) | Reescreve cada comando para a versão filtrada do [rtk](https://github.com/rtk-ai/rtk): 60 a 90% menos tokens em git/test/build. Com guard (`command -v rtk || exit 0`): sem o binário, passa direto, nunca quebra a sessão |

Na máquina, uma vez: `brew install rtk && rtk init -g` (o `-g` põe o hook e o `RTK.md` na config global). **Não rode `rtk init` dentro do repo**: ele injeta ~150 linhas no `CLAUDE.md`, estourando o teto do [doc 01](01-contexto-do-projeto.md), e o hook já faz a reescrita sem instrução nenhuma. Plugin habilitado no repo e ausente na máquina: o Claude Code avisa na abertura; `claude plugins install <nome>` resolve.

## MCP também é dependência

Servidor MCP é código que o agente executa com as suas credenciais, e a regra de supply chain do [doc 03](03-supply-chain.md) vale igual: `npx @playwright/mcp@latest` e `docker run ...:latest` puxam versão nova a cada sessão, sem PR nenhum (é o AST07, *update drift*, do OWASP Agentic Skills Top 10). O [`.mcp.json`](../templates/.mcp.json) template vem pinado: pacote npm em versão exata, imagem Docker por digest (`docker image inspect --format '{{index .RepoDigests 0}}' <imagem>` mostra o digest da que você já roda). Dependabot não lê `.mcp.json`; o bump é manual e entra como PR, com o diff do digest visível.

## Critérios de aceitação que valem reusar

Do PR de origem, e note que são todos **verificáveis por comando**:

- Clone limpo + `npm install` restaura as skills automaticamente.
- `npm run skills:install` restaura do zero de forma idempotente.
- `postinstall` não roda em CI e não quebra o `npm install` offline.
- Falha forçada propaga (`rc != 0`); falha em `--if-missing` é best-effort (`rc = 0` + aviso).

**Fonte**: entrega E5 do estudo de caso ([doc 07](07-licoes-aprendidas.md)); o mesmo mecanismo roda também no painel web do caso de origem.
