# 06. Fluxo de task: da issue ao merge com evidência

O comando de projeto `/task` empacota o ciclo de vida de uma tarefa em duas metades: **`/task <id>`** (pré-step: contexto antes de código) e **`/task close <id>`** (encerramento: prova antes de merge). O desenho vale para qualquer tracker; aqui é o Jira via MCP.

Templates auxiliares: [`.mcp.json`](../templates/.mcp.json) (o tracker plugado no agente) · [`jira-attach.sh`](../templates/scripts/jira-attach.sh) (upload de evidência via REST).

## A infraestrutura: MCP do tracker versionado no repo

O fluxo inteiro depende do agente falar com o Jira (`mcp__jira__*`). Isso não é setup individual de cada dev, é **config de time, versionada**: um `.mcp.json` na raiz do repo ([template](../templates/.mcp.json)), no mesmo espírito do `settings.json` versionado ([doc 04](04-guardrails-do-agente.md)). Quem clona já tem o tracker plugado. O desenho tem três decisões que valem copiar:

1. **O servidor MCP roda em Docker** (`docker run -i --rm` da imagem OSS `mcp-atlassian`): zero instalação local, versão isolada do host, morre com a sessão (`--rm`, nome único por PID, `exec` para propagar sinais). Free, imagem OSS + Docker ([doc 09](09-custos.md)).
2. **Segredo nunca toca o arquivo versionado**: o bootstrap lê `JIRA_USERNAME`/`TOKEN_FOR_JIRA` do `.env` (gitignorado) no momento do launch e injeta como env no container. O `.env.example` documenta as variáveis e onde gerar o token.
3. **Uma fonte de verdade para credenciais**: o mesmo par do `.env` serve o MCP (ler issue, comentar) e o `jira-attach.sh` (upload REST de anexos, caminho que o MCP não cobre). Rotacionou o token, os dois seguem funcionando.

## `/task <id>`, pré-step: proibido codar

Cinco passos, nessa ordem, **sem escrever código**:

1. **Carregar a tarefa**: issue completa (descrição, critérios de aceite, comentários) e **anexos baixados e lidos** (bugs costumam vir com evidência visual). MCP desconectado, avisa e para. *Não inventa conteúdo de issue.*
2. **Tasks relacionadas**: busca JQL por termos/épico/labels. Existe task resolvida parecida (decisão reaproveitável)? Aberta que conflita?
3. **Mapear o código afetado**: localizar a área provável e o padrão vizinho a seguir (as regras do `CLAUDE.md` apontam o caminho, ver [doc 01](01-contexto-do-projeto.md)).
4. **Análise crítica (o passo principal)**, honestamente: a tarefa faz sentido? Critérios claros? Viável na arquitetura atual? Impedimentos, riscos, esforço, por onde começar. **Expor trade-offs, não decidir em silêncio.**
5. **Gate humano**: tudo claro abre brainstorming estruturado; impedimento ou ambiguidade relevante **para e pergunta**.

O agente não cria branch sozinho: sugere o nome (conforme a convenção do repo) e confirma.

## `/task close <id>`, encerramento: prova por critério

O close exige **PR já aberto** e produz duas coisas: push validado e **dois comentários no Jira**, (1) a descrição do PR (fonte única: `gh pr view`, nunca redigida do zero) e (2) a evidência.

### Evidência: um artefato por critério de aceite

A ferramenta de captura muda por stack; o contrato não:

| Stack | Captura | Log |
|---|---|---|
| Mobile (RN/Android) | `adb exec-out screencap` | `adb logcat` filtrado pelo PID do app |
| Web | Playwright (screenshot por rota/estado) | console do browser via Playwright |

Os artefatos vivem num diretório por task (`.task-evidence/<id>/` ou `docs/qa-logs/<id>/`, gitignorado), com uma `_lib/` compartilhada para o que se repete (post de comentário no tracker, helpers de captura). Detalhe que separa tooling sério de gambiarra: **a lib de evidência tem teste próprio**, e o script que posta o comentário no Jira vem com seu `test_*.py`. Tooling de evidência também é código.

Para o app mobile do estudo de caso, a prova é `adb`:

```
adb logcat -c                          # limpa ANTES de reproduzir
# ... reproduz o cenário no app ...
adb logcat -d  > NN-<slug>.full.log    # log bruto
grep <padrões> > NN-<slug>.filtered.log
adb exec-out screencap -p > NN-<slug>.png
```

Regras que fazem a evidência valer algo:

- **Cada critério de aceite vira um item de prova** com veredito **PASSOU / FALHOU / NÃO VERIFICÁVEL**, conferido no print *e* no log filtrado.
- **Falhou? Não maquia.** Reporta como falhou.
- **Sem critérios de aceite na issue, pergunta** se prossegue ("sem critérios não há o que provar"). Não inventa critérios.
- **Triagem de ruído**: separar erro real de ruído do sistema filtrando pelo PID do app, em vez de caçar fantasma de log alheio.
- Upload dos anexos por script REST (não à mão), e o comentário referencia os prints por nome.

### Review duplo antes do merge

Dois reviewers automáticos com papéis distintos, ambos sobre o diff completo da task:

| Reviewer | Papel | Ação |
|---|---|---|
| `code-reviewer` (subagent) | Confronta o diff com as **regras objetivas** do `CLAUDE.md` | Achado bloqueante: corrige e re-pusha **antes do merge** |
| `ponytail-review` (skill) | Caça **over-engineering** (abstração de uso único, dep que stdlib cobre) | Report-only, recomendação para avaliar |

Um confere se o código segue o contrato; o outro, se não fez demais. São falhas diferentes e um reviewer só tende a não pegar as duas.

### `--dry-run`: simular sem efeito colateral

O modo `--dry-run` faz **tudo** (evidência, checklist, reviews) exceto push e comentários no Jira: no lugar, grava os dois comentários como `.md` locais, marcados como simulação. Serve para validar o fluxo (e o próprio comando) sem sujar a issue. Todo fluxo de agente com efeitos externos merece um dry-run.

## Princípios extraíveis (independentes de stack)

1. **Contexto antes de código**: o pré-step é obrigatório, e o passo mais valioso é a análise crítica, não o fetch da issue.
2. **Fonte única**: a descrição vive no PR; Jira recebe espelho. Nunca duas redações que divergem.
3. **Evidência por critério, com veredito honesto.**
4. **Perguntas nos pontos ambíguos, definidos de antemão** (sem critérios? sem PR? tela ambígua? pergunta).
5. **Review duplo com papéis distintos.**
6. **Dry-run para tudo que toca sistema externo.**

**Fonte**: comando `/task` do estudo de caso (entrega E5, [doc 07](07-licoes-aprendidas.md)), nas variantes mobile (adb) e web (Playwright).
