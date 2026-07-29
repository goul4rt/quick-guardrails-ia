# 06 — Fluxo de task: da issue ao merge com evidência

O comando de projeto `/task` empacota o ciclo de vida de uma tarefa em duas metades: **`/task <id>`** (pré-step: contexto antes de código) e **`/task close <id>`** (encerramento: prova antes de merge). O desenho vale para qualquer tracker — aqui o Jira via MCP.

Template auxiliar: [`jira-attach.sh`](../templates/scripts/jira-attach.sh) (upload de evidência via REST).

## `/task <id>` — pré-step: proibido codar

Cinco passos, nessa ordem, **sem escrever código**:

1. **Carregar a tarefa** — issue completa (descrição, critérios de aceite, comentários) e **anexos baixados e lidos** (bugs costumam vir com evidência visual). MCP desconectado → avisa e para. *Não inventa conteúdo de issue.*
2. **Tasks relacionadas** — busca JQL por termos/épico/labels: existe task resolvida parecida (decisão reaproveitável)? Aberta que conflita?
3. **Mapear o código afetado** — localizar a área provável e o padrão vizinho a seguir (as regras do `CLAUDE.md` apontam o caminho — ver [doc 01](01-contexto-do-projeto.md)).
4. **Análise crítica (o passo principal)** — honestamente: a tarefa faz sentido? Critérios claros? Viável na arquitetura atual? Impedimentos, riscos, esforço, por onde começar. **Expor trade-offs, não decidir em silêncio.**
5. **Gate humano** — tudo claro → abre brainstorming estruturado; impedimento ou ambiguidade relevante → **para e pergunta**.

O agente não cria branch sozinho: sugere o nome (conforme a convenção do repo) e confirma.

## `/task close <id>` — encerramento: prova por critério

O close exige **PR já aberto** e produz duas coisas: push validado e **dois comentários no Jira** — (1) a descrição do PR (fonte única: `gh pr view`, nunca redigida do zero) e (2) a evidência.

### Evidência: um artefato por critério de aceite

Para um app mobile, a prova é `adb`:

```
adb logcat -c                          # limpa ANTES de reproduzir
# ... reproduz o cenário no app ...
adb logcat -d  > NN-<slug>.full.log    # log bruto
grep <padrões> > NN-<slug>.filtered.log
adb exec-out screencap -p > NN-<slug>.png
```

Regras que fazem a evidência valer algo:

- **Cada critério de aceite vira um item de prova** com veredito **PASSOU / FALHOU / NÃO VERIFICÁVEL** — conferido no print *e* no log filtrado.
- **Falhou? Não maquia.** Reporta como falhou.
- **Sem critérios de aceite na issue → pergunta** se prossegue ("sem critérios não há o que provar"). Não inventa critérios.
- **Triagem de ruído**: separar erro real de ruído do sistema filtrando pelo PID do app — não caçar fantasma de log alheio.
- Upload dos anexos por script REST (não à mão), e o comentário referencia os prints por nome.

### Review duplo antes do merge

Dois reviewers automáticos com papéis distintos, ambos sobre o diff completo da task:

| Reviewer | Papel | Ação |
|---|---|---|
| `code-reviewer` (subagent) | Confronta o diff com as **regras objetivas** do `CLAUDE.md` | Achado bloqueante → corrige e re-pusha **antes do merge** |
| `ponytail-review` (skill) | Caça **over-engineering** (abstração de uso único, dep que stdlib cobre) | Report-only — recomendação para avaliar |

Um confere se o código segue o contrato; o outro, se não fez demais. São falhas diferentes e um reviewer só tende a não pegar as duas.

### `--dry-run`: simular sem efeito colateral

O modo `--dry-run` faz **tudo** — evidência, checklist, reviews — exceto push e comentários no Jira: no lugar, grava os dois comentários como `.md` locais, marcados como simulação. Serve para validar o fluxo (e o próprio comando) sem sujar a issue. Todo fluxo de agente com efeitos externos merece um dry-run.

## Princípios extraíveis (independentes de stack)

1. **Contexto antes de código** — o pré-step é obrigatório, e o passo mais valioso é a análise crítica, não o fetch da issue.
2. **Fonte única** — a descrição vive no PR; Jira recebe espelho. Nunca duas redações que divergem.
3. **Evidência por critério, com veredito honesto.**
4. **Perguntas nos pontos ambíguos, definidos de antemão** (sem critérios? sem PR? tela ambígua? → pergunta).
5. **Review duplo com papéis distintos.**
6. **Dry-run para tudo que toca sistema externo.**

**Fonte**: [`.claude/commands/task.md` do PR #141](https://github.com/Instivo/instivo-pesquisador-app/pull/141).
