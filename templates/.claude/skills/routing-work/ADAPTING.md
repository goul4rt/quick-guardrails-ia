# Como adaptar esta skill ao seu projeto

Este arquivo NÃO é carregado pelo agente: é o guia de quem copia o template. Depois de adaptar, o que roda é só o `SKILL.md`. Apague este arquivo da sua cópia se quiser.

## O que cada placeholder ⟨...⟩ vira

| Placeholder | Troque por | Exemplo (instância de origem: bot + painel web) |
|---|---|---|
| `⟨seus repos⟩` (na description) | Os nomes reais dos repos cobertos; é o que faz a skill disparar sozinha | "the Acme repos (acme-bot or acme-web / front-end)" |
| `⟨skill de debugging sistemático⟩` | A skill do seu pack, ou instrução inline se não tiver pack | `superpowers:systematic-debugging` (default); `diagnosing-bugs` se cabeludo |
| `⟨brainstorm curto⟩` / `⟨stress-test da decisão⟩` | Suas skills de alinhamento e de questionamento adversarial | `brainstorming` → `grilling` (`grill-with-docs` se render ADR) |
| `⟨sua skill de review⟩` / `⟨review⟩` | UM reviewer canônico, o mesmo nome em todas as menções | `code-review` (eixos Standards+Spec) |
| `⟨proibições do seu contexto⟩` | O que o SEU fluxo proíbe, com o porquê | "Nunca `using-git-worktrees`: múltiplas instâncias no mesmo checkout; isolamento vem da partição por tickets" |
| `⟨repo A/B⟩` + `⟨comandos do gate⟩` | O comando de "verde" real de cada repo, honesto | bot: `npm run lint` + `lang:check` + testes escopados vs master (~20 falhas pré-existentes); front: `tsc --noEmit` + `test:run` + `next build` |

## Regras de adaptação (a parte que importa)

1. **Não tem pack de skills? Não invente referência.** Onde o placeholder pede uma skill que você não tem, escreva a instrução inline ("liste 3 abordagens e os trade-offs antes de codar") ou corte a etapa. Skill que referencia skill inexistente quebra em runtime.
2. **Critérios de tier são observáveis, não subjetivos.** Ao mexer nos tiers, mantenha o teste "outra pessoa classificaria igual?". "1 arquivo, sem lógica nova" passa; "mudança simples" não.
3. **O desempate T2/T3 é a linha mais valiosa** ("se amanhã outra sessão precisar continuar, é T3"). Adapte o resto, preserve essa.
4. **Dono do contrato = quem define o dado.** Com 2+ repos, escolha UM como dono de schema/API e nunca relativize a regra 4, porque é ela que impede migração conflitante e deploy fora de ordem.
5. **Vocabulário do tracker**: se suas skills falam papéis canônicos (`needs-triage`, `ready-for-agent`, ...), mantenha um `triage-labels.md` no repo mapeando papel para label real, em vez de editar cada skill.
6. **Governança**: a skill vive **em todos os repos cobertos**, idêntica. Mudou? Muda em todos no mesmo dia, e só mude quando um caso real falhar no fluxo atual (a mesma regra de "teste falhando" de código).

## Por que a skill é assim (decisões de forma)

- **Model-invoked** (tem `description` com os gatilhos): ela precisa disparar sozinha no início de qualquer task. Se dependesse de você lembrar de invocá-la, seria guardrail de memória, não de processo.
- **Corpo todo referência, sem passos**: roteamento é consulta (classifique, siga a linha da tabela), não sequência. Tabelas flat são a forma certa.
- **"Cerimônia"** é a palavra-âncora da skill: todo o comportamento deriva de "cerimônia escala com o tamanho do trabalho". Se reescrever, preserve uma âncora equivalente.
- **A tabela de erros comuns é viva**: cada erro de roteamento que acontecer de verdade no seu time vira uma linha nela, o changelog dos seus modos de falha.
