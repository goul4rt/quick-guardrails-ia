# 10. Guardrails além do CI: o espectro de enforcement

Guardrail não é só check de pipeline. **Guardrail é qualquer mecanismo que impede um modo de falha conhecido de acontecer de novo, sem depender de alguém lembrar.** Boa parte dos guardrails mais eficazes de um projeto não vive no CI: vive em hooks, workflows de manutenção, skills de roteamento e até na memória do agente. Muitos times já os têm sem saber que são guardrails; este doc dá o vocabulário para inventariá-los e escolher o nível certo para cada falha.

Templates prontos: [`close-sub-issues.yml`](../templates/.github/workflows/close-sub-issues.yml) · [`routing-work/`](../templates/.claude/skills/routing-work/SKILL.md) (skill copiável + guia de adaptação)

> **Origem**: inventário de um segundo ecossistema real, dois repos em produção (um bot e um painel web) que compartilham banco e contrato de API, onde estes mecanismos existiam antes de serem reconhecidos como guardrails. Todos free (regra do [doc 09](09-custos.md)).

## O espectro: do mais duro ao mais macio

| Nível | Mecanismo | Quando falha, o que acontece | Exemplo real |
|---|---|---|---|
| 1. **Hook do harness** | `PreToolUse`/`PostToolUse`, determinístico, roda sempre | A ação **não executa** | `block-dangerous-git.sh` ([doc 04](04-guardrails-do-agente.md)); rewrite automático de comandos via proxy de CLI |
| 2. **Gate de CI + branch protection** | Check bloqueante | O merge **não acontece** | `ci.yml` ([doc 02](02-gate-de-ci.md)), `security.yml` ([doc 08](08-seguranca-no-gate.md)) |
| 3. **Automação de invariante** | Workflow que corrige estado inconsistente sozinho | O estado **se auto-corrige** | Cascata de fechamento de sub-issues (abaixo) |
| 4. **Contrato de contexto** | Regra objetiva no `CLAUDE.md`, carregada toda sessão | O agente **sabe e obedece** (probabilístico, mas presente sempre) | Anti-patterns com porquê; regras de STOP ([doc 01](01-contexto-do-projeto.md) e abaixo) |
| 5. **Skill de roteamento** | Processo invocado por gatilho, com critérios observáveis | O trabalho **entra no fluxo certo** | skill de roteamento por tiers (abaixo) |
| 6. **Memória do agente** | Regra aprendida de feedback, recuperada por relevância | O erro **tende** a não repetir | "nunca stash pop cego", "grounding antes de aceitar premissa de issue" |

**Regra de escolha**: para cada modo de falha, use o nível mais duro que o custo permite. Perda de trabalho pede nível 1 (hook). Regressão de código, nível 2 (gate). Estado de board inconsistente, nível 3 (automação). Convenção de arquitetura, nível 4 (contrato). Processo desproporcional, nível 5 (roteamento). Preferência pessoal de fluxo, nível 6 (memória). Descer um nível (ex.: confiar convenção crítica só à memória) é aceitar que a falha vai acontecer de vez em quando.

## Nível 3 na prática: cascata de sub-issues

O GitHub **não fecha sub-issues quando a issue-pai fecha**, e cada pai concluído deixa órfãs abertas sujando board e métricas. Pedir "lembre de fechar as filhas" é guardrail de nível 6 (vai falhar). A versão nível 3 é um workflow de 60 linhas ([template](../templates/.github/workflows/close-sub-issues.yml)) que merece cópia pelos detalhes:

- **Dispara no evento certo** (`issues: closed`) e **pula o caso semanticamente errado**: pai fechado como `not_planned` não conclui as filhas.
- **Cross-repo com degradação graciosa**: `SUB_ISSUE_TOKEN || GITHUB_TOKEN`. Com o PAT fecha sub-issues em outros repos; sem ele, fecha as do próprio repo e **avisa** no log o que não conseguiu (limite visível, não silencioso, [doc 07](07-licoes-aprendidas.md), lição 7).
- **Trilha de auditoria**: comenta em cada filha *por que* está sendo fechada (link para a pai) antes de fechar.
- **Falha isolada**: erro numa filha não aborta a cascata das outras.

## Nível 4 na prática: a regra de STOP

Além dos anti-patterns com porquê ([doc 01](01-contexto-do-projeto.md)), o `CLAUDE.md` do caso de origem tem um padrão que merece nome: a **regra de STOP**, para operações onde o caminho "resolver o erro" é catastrófico.

> Se o `db push` pedir `--accept-data-loss`, **PARE**: rode `db pull`, re-adicione seu model e pushe de novo. **NUNCA** passe `--accept-data-loss` para silenciar.

A anatomia: (1) o sintoma exato que o agente vai ver, (2) a ordem de parar, (3) o caminho correto, (4) a proibição explícita do atalho. Sem isso, um agente diante do prompt "adicione `--accept-data-loss`?" tende a obedecer o erro, que aqui dropa tabelas do outro repo. Escreva uma regra de STOP para cada operação do projeto em que o "fix" sugerido pela ferramenta é a catástrofe.

## Nível 5 na prática: cerimônia proporcional por tiers

A skill de roteamento do caso de origem resolve dois modos de falha opostos: trabalho grande sem processo (caos) e trabalho trivial afogado em processo (teatro). O princípio de abertura:

> Cerimônia escala com o tamanho do trabalho, não com a vontade de rigor.

Mecânica que vale copiar para qualquer projeto:

- **Tiers com critério observável**, não subjetivo: T0 = "1 arquivo, sem lógica nova"; T3 = "sobrevive à sessão OU toca dois repos OU deve aparecer no board". Desempate operacional: *"se amanhã outra sessão precisar continuar, é T3"*.
- **Fluxo fixo por tier**, de "zero specs/issues/planos" (T0) a spec + tickets + implementação por sessão (T3). A decisão de quanto processo aplicar é tomada **uma vez, na skill**, não renegociada a cada task.
- **Decisões fixas anti-duplicação**: um único reviewer por diff (não somar reviewers), verificação antes de qualquer "pronto", e proibições explícitas do que *não* usar (worktrees com múltiplas instâncias, subagentes onde a partição por tickets já dá o paralelismo).
- **"Verde" definido por repo, contra baseline**: a suíte do bot carrega ~20 falhas pré-existentes, então o critério é comparar com master, não exigir zero ([doc 07](07-licoes-aprendidas.md), lição 3).
- **Tabela de erros comuns** com a correção ao lado: os modos de falha do próprio processo, documentados.
- **Regras cross-repo como contrato**: spec-pai sempre no repo dono do contrato (schema + API); ordem fixa schema → endpoint → consumo; "1 sessão = 1 ticket = 1 repo".

Governança da skill: vive **nos dois repos**, e só muda com os dois sincronizados. A skill de processo é código compartilhado, com a mesma disciplina.

> **Versão copiável**: [`templates/.claude/skills/routing-work/`](../templates/.claude/skills/routing-work/SKILL.md) traz a skill genérica com placeholders `⟨...⟩` + [`ADAPTING.md`](../templates/.claude/skills/routing-work/ADAPTING.md) explicando o que trocar, as regras que não se relativizam (dono do contrato, desempate T2/T3) e as decisões de forma (por que model-invoked, por que tabelas flat).

## A segunda dimensão: o que acontece quando dispara

O espectro acima diz **onde** o guardrail vive; falta decidir **qual é a resposta** ao disparo. Os frameworks de guardrail de runtime de LLM (ver [doc 12](12-fronteira-runtime.md)) têm essa taxonomia fechada e nomeada há anos, as ações "on fail", e ela mapeia 1:1 para guardrails de desenvolvimento:

| Resposta | No runtime | Em guardrail de dev |
|---|---|---|
| **Bloquear** | exception | hook `exit 2`; check vermelho no gate |
| **Corrigir determinístico** | fix | `lint --fix`, formatter, codemod (o hook de `PostToolUse` do [doc 04](04-guardrails-do-agente.md)) |
| **Corrigir, revalidar, só então escalar** | fix + reask | o fixer roda primeiro; o agente só é acionado se o gate *ainda* reprovar |
| **Devolver a falha a quem gerou** | reask | o stderr do hook volta ao modelo como novo turno, e funciona na proporção da qualidade da mensagem ([doc 04](04-guardrails-do-agente.md)) |
| **Só registrar** | noop | modo warn-only para estrear regra nova sem quebrar ninguém, com prazo para virar bloqueante, senão vira decoração ([doc 02](02-gate-de-ci.md)) |

Duas regras derivadas:

- **Fixer determinístico antes de turno de agente.** Nunca gaste uma rodada do modelo consertando o que `prettier --write` conserta. É o free-first aplicado ao orçamento da assinatura: o determinístico é grátis e instantâneo; o agente é o recurso caro da cadeia.
- **Auto-fix sem fallback é fail-open disfarçado.** Se o `--fix` não conseguiu corrigir, o gate **reprova**, e nunca deixa passar o valor original em silêncio. Um auto-fix sem caminho de falha definido é um guardrail que às vezes não guarda nada.

## Quem pode mudar o guardrail

Regra de governança que os níveis 1 a 5 pressupõem e ninguém escreve: **o agente não edita o próprio guardrail no mesmo fluxo em que trabalha**. A checagem roda fora do loop de controle do agente (hook, CI), e mudança de política (nova regra, exceção, calibragem) passa por aprovação humana explícita, como qualquer código: PR revisado, ou fluxo rascunho → confirmação → vigência. Sem isso, o caminho de menor resistência diante de um bloqueio é "ajustar" a regra que bloqueou, e o guardrail vira sugestão. (O mesmo motivo pelo qual exceção de gitleaks é `.gitleaksignore` com justificativa em PR, nunca desligar o job, [doc 08](08-seguranca-no-gate.md).)

## Complementos menores do inventário

- **Nível 1, hooks de git (husky)**: enquanto os hooks do Claude Code valem só para o agente, `pre-commit`/`pre-push` valem para **humano e agente**, validando o padrão do nome da branch e bloqueando commit direto nas branches de integração ([template](../templates/.husky/pre-commit)). O detalhe que separa hook bom de hook chato: **skips explícitos** para detached HEAD e rebase/cherry-pick/merge em andamento. Sem eles o hook quebra operações legítimas do git e vira incentivo cultural ao `--no-verify`.
- **Nível 1, proxy de CLI por hook**: um `PreToolUse` global reescreve comandos de dev para versões com saída otimizada em tokens (`git status` vira `rtk git status`, transparente). Guardrail de **custo**: o agente não precisa lembrar de economizar contexto; o harness economiza por ele.
- **Nível 2, smoke do preview de deploy**: o gate de código não prova que o deploy sobe; um workflow disparado pelo `check_run` da plataforma valida as rotas principais do preview. Ver [doc 02](02-gate-de-ci.md) e [template](../templates/.github/workflows/preview-smoke.yml).
- **Adaptador de vocabulário**: um `triage-labels.md` mapeando os papéis canônicos que as skills falam (`needs-triage`, `ready-for-agent`, ...) para as labels reais do tracker. Skills genéricas + tabela local = skills portáveis sem fork.
- **Nível 6, honestamente**: regras de memória ("nunca `stash pop` cego", "push via credential helper do gh", "issue de backlog pode alegar infra que não existe: grounding antes de aceitar premissa") funcionam, mas por sessão e por relevância. Quando uma regra de memória falha pela segunda vez, é sinal de que ela quer subir de nível: virar hook, contrato ou automação.

## Como inventariar os seus

Três perguntas sobre qualquer coisa que seu time já automatizou ou padronizou:

1. **Que falha isso impede?** Se há resposta, é guardrail. Dê esse nome e documente a falha junto.
2. **Em que nível está?** E a falha que ele previne justificaria um nível mais duro?
3. **O que hoje só está na sua cabeça (ou na memória do agente)?** Cada regra repetida duas vezes em review é candidata a subir de nível.
