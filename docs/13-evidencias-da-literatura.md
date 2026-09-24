# 13. Evidências da literatura (2023 a 2026)

Os docs deste repo nasceram de prática. Este doc registra os **números públicos** que sustentam cada escolha, para citar em decisão, PR ou discussão de orçamento, sem precisar refazer a pesquisa. Compilado em jul/2026; OWASP e Gartner adicionados em set/2026.

## Os números, e o que cada um sustenta aqui

| Evidência | Número | Sustenta |
|---|---|---|
| Veracode, *GenAI Code Security Report* 2025 (100+ LLMs, 80 tasks) | **45%** das tasks introduzem vulnerabilidade OWASP Top 10 detectável; estável entre gerações de modelo | Gate bloqueante ([doc 02](02-gate-de-ci.md)) e scan determinístico ([doc 08](08-seguranca-no-gate.md)): código de IA é não-confiável-até-verificado |
| GitClear, *Maintainability Gap* 2026 (600M+ commits) | Duplicação de blocos **+81%** (2023 a 2026); código refatorado ou "movido" caiu de ~25% para <10% das linhas | Contexto do projeto apontando para abstrações existentes ([doc 01](01-contexto-do-projeto.md)): o agente duplica o que não sabe que existe |
| Spracklen et al., USENIX Security 2025 (16 LLMs, 2,23M amostras) | **19,7%** das amostras citam pacote alucinado; 43% dos nomes alucinados se repetem em toda execução (*slopsquatting* pré-registrável) | Pins exatos + lockfile + verificação de dependência antes do install ([doc 03](03-supply-chain.md)) |
| DORA (Google) 2024/2025 | IA é **amplificador**: melhora throughput (2025), mas a instabilidade de entrega persiste nos dois anos | O método inteiro: guardrails primeiro, volume depois. Sem gate, IA amplifica o caos |
| GitHub RCT 2023 (Peng et al.) | **55,8%** mais rápido com Copilot, sem diferença significativa na taxa de conclusão | Velocidade individual não é resultado de entrega; o gargalo vira verificação |
| GitHub RCT 2024 (202 devs Python) | Com IA: +53,2% de chance de passar todos os testes, **quando há testes para passar** | Suite como critério verificável ([doc 06](06-fluxo-de-task.md)): evidência, não afirmação |
| Anthropic, *When AI builds itself* (jun/2026) | 80%+ do código mergeado é de autoria do Claude; reviewer automático teria pego ~1/3 dos bugs de incidentes passados | Alta autoria de IA é viável **com** review obrigatório em camadas ([doc 08](08-seguranca-no-gate.md), camada 2) |
| Gloaguen et al. 2026 (138 repos) | Arquivo de contexto **gerado por LLM** reduz taxa de sucesso do agente e custa +20% de inferência | `CLAUDE.md` curado à mão, guia e não enciclopédia ([doc 01](01-contexto-do-projeto.md)) |
| Tanaka et al. 2025 (arXiv 2510.25297) | Testes por propriedade e baseados em exemplo: 68,75% de bugs cada, **81,25% combinados** | Diversidade de verificação ganha de mais do mesmo teste; contra o ciclo de auto-engano (teste de IA herda o ponto cego do código de IA) |
| OWASP, *Agentic Skills Top 10* 2026 (AST10, CC BY-SA 4.0) | Skill maliciosa (AST01) e comprometimento de registro (AST02) são os dois riscos **críticos**; *update drift* (AST07) tem como mitigação-chave pinning imutável e verificação de hash | Skills fixadas por hash e MCP pinado por versão/digest ([doc 05](05-skills-versionadas.md)) |
| OWASP, *State of Agentic AI Security and Governance* v2.01 (2026) | ASI02/ASI04/ASI05 (uso indevido de ferramenta, supply chain agêntica, execução de código inesperada): agente de código se contém no **servidor** (branch protection, CODEOWNERS), não só na própria config | Bloco 3 do CHECKLIST: guardrail local + servidor; `CODEOWNERS` sobre a config que o agente executa |
| Gartner, G00847850 *Redesign Governance and Risk Management for AI-Native Software Engineering* (abr/2026) | Guardrails embutidos na plataforma e gates de CI/CD estendidos aos artefatos gerados por agente, não camada de governança à parte | O método inteiro ([doc 02](02-gate-de-ci.md), [doc 04](04-guardrails-do-agente.md)): guardrail no harness e no gate, não no prompt |
| Mutation testing (relatos de praticantes) | Suites geradas por IA matam 40 a 50% dos mutantes, contra 70 a 85% das humanas | Cobertura de linha não mede força de assert; mutation score é a métrica honesta para módulo de autoria IA |

## O que a literatura recomenda e ficou FORA dos templates

Pela regra de admissão do [doc 09](09-custos.md) (exige serviço pago ou cobrança por token, então não entra):

- **SonarQube/SonarCloud** (quality gate "Clean as You Code"), pago para repo privado. O equivalente free parcial: gate de lint/types zerado + cobertura em código novo via script.
- **CodeRabbit / Copilot code review / Claude Code Action como reviewer**, com cobrança por token ou assinatura extra. O desenho certo está registrado no [doc 08](08-seguranca-no-gate.md) camada 2 para quando houver orçamento.
- **CodeQL**, que exige GitHub Advanced Security em repo privado. Semgrep CE (CLI, free) cobre a camada SAST.
- Entram sem ressalva (free, e a literatura converge): **pins por SHA + Dependabot** ([doc 03](03-supply-chain.md)), **gitleaks CLI** ([doc 08](08-seguranca-no-gate.md)), **AGENTS.md** como padrão neutro de contexto (symlink de `CLAUDE.md`, complemento ao [doc 01](01-contexto-do-projeto.md)), **mutation testing** e **property-based testing** (Stryker/mutmut e fast-check/Hypothesis, OSS, prática no [doc 14](14-forca-de-teste.md)).

## Como ler esses números

- Boa parte vem de **vendors com interesse comercial** (Veracode, GitClear, CodeRabbit). A direção converge entre fontes independentes; os percentuais exatos são indicativos, não definitivos.
- DORA é **correlacional**, não causal, e mudou entre 2024 e 2025 (throughput inverteu; instabilidade persistiu). Sinal de prontidão organizacional, não lei.
- Números de autoria ("80% do código é da IA") são **autorreportados**, não auditados.
- Capacidades e preços de ferramenta mudam rápido; verifique versão e preço antes de adotar qualquer coisa citada aqui.

## Ligação com o resto do método

Nenhum número acima pede ferramenta nova por si só. Eles quantificam o que os docs 01 a 12 já assumem: **o agente produz volume; o gate produz confiança**. Quando alguém perguntar "por que tanto guardrail?", a resposta curta é a linha 1 da tabela.
