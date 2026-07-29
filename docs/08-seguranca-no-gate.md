# 08 — Segurança no gate: scanner determinístico bloqueia, IA recomenda

Os docs anteriores cobrem o gate de qualidade (lint, tipos, testes) e a supply chain (vulnerabilidade de dependência). Falta a camada de **segurança do código em si**: secrets commitados, injeção, permissão insegura. É aqui que entra a ideia de "AI-powered DevSecOps guardrail" — que funciona, mas só com os papéis certos.

Template pronto: [`security.yml`](../templates/.github/workflows/security.yml)

> **Origem**: artigo *Building an AI-Powered DevSecOps Guardrail Pipeline with GitHub Actions* (E. Opurum, HackerNoon, 2026) e o repo de referência dele. A arquitetura proposta — job de scan de IA antes do build (`needs:`), alerta imediato no Slack — está certa. A implementação de referência comete erros instrutivos, analisados abaixo; extraímos o desenho e corrigimos a execução.

## As três camadas, por confiabilidade

| Camada | Ferramenta | Determinística? | Papel |
|---|---|---|---|
| 1. Secrets | `gitleaks` | Sim | **Bloqueante** — secret no diff trava o PR, sempre |
| 2. Review semântico | `claude-code-security-review` | Não | **Recomendação** — comenta achados no PR; humano decide |
| 3. Triagem de falha | LLM lendo o log do build | Não | **Pós-falha** — explica a quebra no alerta; zero poder de gate |

A regra que ordena tudo (é o princípio 2 do [README](../README.md) aplicado a segurança): **o que bloqueia precisa ser determinístico; o que é probabilístico recomenda.** Um check bloqueante que ora passa ora falha no mesmo código destrói a confiança no gate — e a resposta cultural é bypass, não correção.

### Camada 1 — secrets: o caso perfeito para bloqueio

Detecção de secret é pattern-matching com baixíssimo falso positivo: regex + entropia, resultado reproduzível. `gitleaks` no PR com `fetch-depth: 0` (varre os commits do PR, não só o estado final — secret commitado e "removido" no commit seguinte continua no histórico). Complementa o [doc 03](03-supply-chain.md): o `audit.yml` cuida de vulnerabilidade *de dependência*; o gitleaks, de segredo *seu*.

### Camada 2 — review de IA: no diff, com filtro, sem martelo

O valor real de IA em segurança é o que regex não pega: lógica de autorização furada, injeção via caminho indireto, PII em log. O action oficial `anthropics/claude-code-security-review` acerta o desenho:

- **Analisa o diff do PR**, não o repositório inteiro — escopo pequeno, contexto relevante.
- **Filtro de falsos positivos embutido** (e customizável) antes de comentar.
- **Comenta no PR** — o achado chega como recomendação revisável, não como veredito binário.

Default recomendado: **não-bloqueante**. Se o time quiser endurecer depois, o action expõe `findings-count` como output — dá para falhar o job acima de um limiar, com o histórico de precisão já observado no próprio repo como justificativa.

### Camada 3 — IA explicando a falha do build

A ideia mais reaproveitável do artigo de origem, e a de menor risco: quando o build falha, um LLM lê o log e posta no Slack **causa raiz + fix sugerido + prevenção** junto do link do run. Roda *depois* da falha (`if: failure()`), então não tem poder de gate nenhum — se a análise for ruim, o custo é um parágrafo ruim no Slack, não um merge travado. Ótimo primeiro passo para times céticos de IA no pipeline.

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

Nenhum desses erros é exótico — são o caminho natural de quem conecta um LLM no CI sem separar *bloquear* de *recomendar*. Por isso valem documentação.

## Ligação com o resto do método

- O `security.yml` segue as regras do [doc 02](02-gate-de-ci.md): `permissions: contents: read` (+ `pull-requests: write` só no job que comenta), `timeout-minutes`, jobs baratos primeiro.
- Secret **de produção** nunca toca o gate — o review de IA usa uma API key própria (`secrets.ANTHROPIC_API_KEY`) com escopo único.
- Falso positivo do gitleaks se trata como qualquer guardrail simples ([doc 04](04-guardrails-do-agente.md)): documenta e usa `.gitleaksignore` pontual com justificativa no commit — não desliga o scanner.
