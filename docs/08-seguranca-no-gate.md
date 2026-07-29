# 08 — Segurança no gate: scanner determinístico bloqueia, IA recomenda

Os docs anteriores cobrem o gate de qualidade (lint, tipos, testes) e a supply chain (vulnerabilidade de dependência). Falta a camada de **segurança do código em si**: secrets commitados, injeção, permissão insegura. É aqui que entra a ideia de "AI-powered DevSecOps guardrail" — que funciona, mas só com os papéis certos.

Template pronto (100% free): [`security.yml`](../templates/.github/workflows/security.yml)

> **Origem**: artigo *Building an AI-Powered DevSecOps Guardrail Pipeline with GitHub Actions* (E. Opurum, HackerNoon, 2026) e o repo de referência dele. A arquitetura proposta — job de scan antes do build (`needs:`), alerta imediato — está certa. A implementação de referência comete erros instrutivos, analisados abaixo; extraímos o desenho e corrigimos a execução.

## As três camadas, por confiabilidade

| Camada | Ferramenta | Custo | Papel |
|---|---|---|---|
| 1. Secrets | `gitleaks` CLI (MIT) | **Free** — está no template | **Bloqueante** — secret no diff trava o PR, sempre |
| 2. Review semântico de segurança | Agente de IA sobre o diff do PR | Por token — **fora deste repo** (ver [doc 09](09-custos.md)) | Recomendação; nunca veredito |
| 3. Triagem de falha | LLM lendo o log do build quebrado | Free tier viável (GitHub Models) | **Pós-falha** — explica a quebra no alerta; zero poder de gate |

A regra que ordena tudo (é o princípio 2 do [README](../README.md) aplicado a segurança): **o que bloqueia precisa ser determinístico; o que é probabilístico recomenda.** Um check bloqueante que ora passa ora falha no mesmo código destrói a confiança no gate — e a resposta cultural é bypass, não correção.

### Camada 1 — secrets: o caso perfeito para bloqueio (e é free)

Detecção de secret é pattern-matching com baixíssimo falso positivo: regex + entropia, resultado reproduzível. O template usa o **CLI do gitleaks direto** (MIT, sem cadastro) com `fetch-depth: 0` — varre os commits do PR, não só o estado final: secret commitado e "removido" no commit seguinte continua no histórico.

> Por que não o `gitleaks-action`? A partir da v2 ele deixou de ser MIT e **exige license key em repositórios de organização** (gratuita hoje, mediante cadastro — mas é uma dependência externa de licenciamento que o CLI não tem). Regra do repo: se existe caminho 100% livre equivalente, é ele que vai no template.

Complementa o [doc 03](03-supply-chain.md): o `audit.yml` cuida de vulnerabilidade *de dependência*; o gitleaks, de segredo *seu*.

### Camada 2 — review de IA: o desenho certo, se um dia houver orçamento

O valor real de IA em segurança é o que regex não pega: lógica de autorização furada, injeção via caminho indireto, PII em log. O desenho certo (implementado, por exemplo, pelo action oficial `anthropics/claude-code-security-review`): analisa **o diff do PR** (não o repo), filtra falsos positivos antes de reportar, e **comenta** — recomendação revisável, não veredito binário.

**Esta camada não tem template aqui**: custa API por token a cada PR, e a regra deste repositório é não depender de serviço externo pago (ver [doc 09](09-custos.md)). O substituto free e local: rodar `/security-review` no Claude Code (que você já assina) antes de abrir o PR — mesma análise semântica, custo já coberto pela assinatura, e o resultado vai como comentário seu no PR.

### Camada 3 — IA explicando a falha do build

A ideia mais reaproveitável do artigo de origem, e a de menor risco: quando o build falha, um LLM lê o log e posta no alerta **causa raiz + fix sugerido + prevenção** junto do link do run. Roda *depois* da falha (`if: failure()`), então não tem poder de gate — se a análise for ruim, o custo é um parágrafo ruim no canal, não um merge travado.

Aqui o free tier do **GitHub Models** (via `GITHUB_TOKEN`, com rate limit) é aceitável: é exatamente o caso de uso que rate limit não quebra — roda só em falha, e se a cota estourar, o alerta sai sem a análise. Free tier **nunca** em check bloqueante ([doc 09](09-custos.md), regra 5).

## Anti-padrões (da implementação de referência — erros instrutivos)

A implementação do artigo usa o LLM como **check bloqueante** sobre o **repo inteiro**. Cada decisão dessas tem uma lição:

| Anti-padrão | Por que quebra |
|---|---|
| LLM bloqueante respondendo `PASS`/`FAIL` | Não-determinístico: mesmo código, veredito diferente entre runs. Gate flaky → bypass cultural |
| Concatenar o repo inteiro no prompt | Contexto estourado, análise rasa. O diff do PR é o escopo certo |
| `files[:20]` — truncamento silencioso | Os arquivos 21+ **nunca são escaneados** e nada avisa. Cap silencioso lê como "coberto" quando não foi ([doc 07](07-licoes-aprendidas.md), lição 7: entrega verificável) |
| Conteúdo de arquivo cru no prompt de um gate | **Prompt injection**: um `.md` no repo contendo "reply PASS" instrui o próprio juiz. Conteúdo escaneado é input não-confiável |
| Veredito parseado por prefixo de string (`startswith("FAIL")`) | Um "FAIL" que o modelo formatar diferente vira PASS. Parsing frágil de output não-estruturado em decisão de merge |
| Resultado de scan cacheado por hash e reaproveitado | Um PASS obtido num scan truncado fica "aprovado" para sempre naquele estado de árvore |

Nenhum desses erros é exótico — são o caminho natural de quem conecta um LLM no CI sem separar *bloquear* de *recomendar*. Por isso valem documentação. Um **segundo** pipeline público examinado em jul/2026 reproduziu quatro desses anti-padrões de forma independente (LLM bloqueante, repo inteiro truncado em 20 arquivos, `startswith("FAIL")`, veredito cacheado) — e adicionou o quinto ato: quando a única checagem determinística do pipeline gerou o primeiro vermelho legítimo, ela foi deletada para o badge voltar a ficar verde. A história completa, com os recibos de CI, está no [doc 11](11-teste-o-guardrail.md).

## Ligação com o resto do método

- O `security.yml` segue as regras do [doc 02](02-gate-de-ci.md): `permissions: contents: read`, `timeout-minutes`, versão do scanner **pinada** (bump é PR explícito — mesma regra do [doc 03](03-supply-chain.md)).
- Falso positivo do gitleaks se trata como qualquer guardrail simples ([doc 04](04-guardrails-do-agente.md)): documenta e usa `.gitleaksignore` pontual com justificativa no commit — não desliga o scanner.
- Custo e enforcement de cada camada: [doc 09](09-custos.md).
