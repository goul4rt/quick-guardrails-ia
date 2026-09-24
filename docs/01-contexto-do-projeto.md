# 01. Contexto do projeto: `CLAUDE.md` como contrato operacional

O `CLAUDE.md` na raiz é carregado automaticamente pelo Claude Code a cada sessão. Tratado com rigor, ele deixa de ser "documentação que ninguém lê" e vira o **contrato operacional do agente**: o que ele pode presumir, o que deve perguntar e quais regras são inegociáveis.

## O que um bom `CLAUDE.md` tem

### 1. Postura antes de código

A seção mais importante não é técnica. O `CLAUDE.md` do projeto de referência abre com:

> **Não presuma. Não esconda dúvidas. Exponha os trade-offs.**
>
> - Declare suas suposições de forma explícita. Em caso de incerteza, pergunte.
> - Se houver mais de uma interpretação, apresente-as; não escolha silenciosamente.
> - Se existir uma abordagem mais simples, diga. Questione quando fizer sentido.
> - Se algo estiver confuso, pare, aponte o que não está claro e pergunte.

Isso muda o comportamento do agente em toda decisão ambígua, de "escolher e seguir" para "expor e alinhar".

### 2. Regras objetivas e verificáveis

Regra vaga ("escreva código limpo") não muda comportamento. Regra objetiva sim:

- **Convenção de `data-testid`**: kebab-case, ação por último (`submit-button`, não `button-submit`), nunca valor dinâmico, único por tela, só em elementos críticos, com exemplos ✅/❌ em código.
- **Fluxo de branches em tabela**: de onde cada tipo nasce, para onde abre PR, o que recebe merge. O agente consulta a tabela em vez de adivinhar.
- **Canal único de data fetching**: "toda chamada nova segue o padrão do serviço vizinho" aponta o diretório e o padrão, em vez de descrever abstratamente.

Cada regra dessas é **checável num diff**: um reviewer (humano ou agente) consegue dizer objetivamente se foi violada.

### 2b. Válvulas de escape nomeadas, com justificativa obrigatória

Todo gate tem um escape hatch (`# noqa`, `eslint-disable`, `@ts-expect-error`, `--no-verify`, `testPathIgnorePatterns`), e um agente pressionado a "fazer o check passar" vai encontrá-lo. O contrato não finge que a válvula não existe: **nomeia cada uma e exige comentário com o porquê** ao lado do uso, regra checável por lint. Complementos da mesma família:

- **Cláusula anti-cosmética**: quando um gate reprovar, a instrução é repensar a causa ("repense a forma dos dados"), não reescrever até o gate calar. Satisfazer o gate sem satisfazer a intenção é gaming, e o agente faz isso por default se ninguém proibir.
- **Gate aponta, doc de remediação orienta**: o check diz *o que* violou; um doc curto diz *como escolher* a correção (um fluxograma de decisão, não prosa). Sem ele, a "correção" degenera na cosmética acima.
- Pisos são pisos: "cobertura ≥ 80%" acompanha "nunca *reduzir* cobertura", senão o piso vira teto.

### 3. Gotchas com o porquê

Gotcha sem contexto vira superstição; com contexto, vira conhecimento transferível:

- "Nunca tocar na pasta `drizzle/`" + o porquê (quebra as migrations).
- "`isInternetReachable` pode retornar `false` com rede ativa; não use para gating de lógica crítica."
- Padrões de performance com o código do erro e do acerto lado a lado (ex.: `keyExtractor` estável, paginação em query, busca no blur e não por keystroke).

### 4. Ponte para o humano

O `README.md` ganha uma seção **"Desenvolvendo com IA"** explicando à equipe: o que o `CLAUDE.md` é, quais comandos de projeto existem (`/task`), como as skills chegam na máquina de cada dev e quais plugins instalar. O contrato do agente e o onboarding do humano apontam um para o outro.

### 5. `AGENTS.md` é a fonte; `CLAUDE.md` importa

`AGENTS.md` é o padrão neutro de arquivo de contexto (aberto pela OpenAI em 2025, hoje sob a Agentic AI Foundation da Linux Foundation; lido por Codex, Cursor, Copilot, Jules, Gemini CLI e afins). O contrato mora nele, e o `CLAUDE.md` só aponta:

```markdown
@AGENTS.md

## Claude Code

⟨só o que é exclusivo do Claude Code: hooks, skills, plan mode. Vazio é o caso normal.⟩
```

Por que import e não symlink: o `CLAUDE.md` ganha lugar para o que só vale no Claude Code sem sujar o contrato dos outros agentes, e import funciona igual no Windows, onde symlink versionado costuma virar arquivo de texto. O Claude Code também lê `AGENTS.md` direto quando não há `CLAUDE.md`, mas um `CLAUDE.local.md` pessoal desliga essa leitura em silêncio ([doc oficial](https://code.claude.com/docs/en/memory#agents-md)); o import não tem essa pegadinha.

**Nunca duplique o conteúdo em dois arquivos**: contratos duplicados divergem em silêncio, e cada agente passa a operar sob regras diferentes ([doc 13](13-evidencias-da-literatura.md) tem a evidência de que arquivo de contexto ruim é pior que nenhum).

### 6. Orçamento de tamanho, senão o guia vira enciclopédia

As cinco seções acima só adicionam, e é assim que um `CLAUDE.md` cresce 60% numa auditoria e ninguém percebe: cada item, isolado, se justifica. O contrato precisa de um teto declarado no próprio arquivo e de uma regra de troca: **seção nova nomeia o que foi consolidado ou removido**, a mesma disciplina que o repo aplica a código. Sem isso o arquivo continua tecnicamente correto e para de ser lido, que é o modo de falha mais caro deste doc: o agente carrega tudo a cada sessão, então o custo do inchaço é pago em toda tarefa, não uma vez.

## O fluxo para escrever

O arquivo sai de quatro fases, nesta ordem, empacotadas na skill [`writing-agents-md`](../.claude/skills/writing-agents-md/SKILL.md) (vem no plugin `guardrails`; peça "escreva o AGENTS.md deste repo"):

1. **Fatos**: o agente descobre sozinho stack, comandos (rodando cada um), convenções visíveis e contexto que já exista. Separa o que parece decisão mas o código não explica.
2. **Entrevista**: `grilling` + `domain-modeling` do [`mattpocock-skills`](https://github.com/mattpocock/skills) (o par que o `/grill-with-docs` dispara) sobre essas decisões, uma pergunta por vez. Termo resolvido vai para `CONTEXT.md`; decisão difícil de reverter, surpreendente e fruto de trade-off vira ADR em `docs/adr/`.
3. **Escrita**: `AGENTS.md` pelas seis seções acima, abaixo de 200 linhas (o limite que a própria Anthropic recomenda), e `CLAUDE.md` com `@AGENTS.md`.
4. **Auditoria**: `claude-md-improver` (plugin oficial `claude-md-management`) sobre o par. Em conflito com este doc, este doc vence: o improver tende a sugerir seção de arquitetura, e o teto ganha.

A separação 1 × 2 é a que a skill `applying-guardrails` já usa: fato se descobre, decisão se pergunta. Um `CLAUDE.md` inventado pelo agente sem a Fase 2 é o erro nº 2 do baseline do README.

## Exceções documentadas, não escondidas

Quando o trabalho precisou fugir da convenção (um PR de tooling apontando `task/*` direto para `master`, fora do fluxo padrão), a exceção foi **declarada no corpo do PR** com a justificativa e o registro explícito de que a convenção não mudou:

> Este PR aponta `task/<id>` **direto para `master`**, o que foge da convenção do `CLAUDE.md` (...). Exceção **intencional e pontual**: é trabalho de tooling/config (`chore`), sem código de app (...). Decisão registrada aqui a pedido; a convenção não foi alterada.

A alternativa, quebrar a regra em silêncio, corrói o contrato: se o agente vê exceções não explicadas no histórico, aprende que as regras são opcionais.

## Anti-padrões

| Não faça | Porquê |
|---|---|
| `CLAUDE.md` gigante com prosa genérica | O agente carrega tudo a cada sessão; sinal se dilui em ruído |
| Regras sem exemplo de código | "Use bons nomes" não é verificável; um ✅/❌ é |
| Documentar o que o código já mostra | Estrutura de pastas muda; deixe o mapa mínimo e aponte referências vivas |
| Regra sem porquê | Vira carga cognitiva morta; com porquê, o agente generaliza para casos novos |

**Fonte**: `CLAUDE.md` e `README.md` do app mobile do estudo de caso (entrega E5, [doc 07](07-licoes-aprendidas.md)).
