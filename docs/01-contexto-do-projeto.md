# 01 — Contexto do projeto: `CLAUDE.md` como contrato operacional

O `CLAUDE.md` na raiz é carregado automaticamente pelo Claude Code a cada sessão. Tratado com rigor, ele deixa de ser "documentação que ninguém lê" e vira o **contrato operacional do agente**: o que ele pode presumir, o que deve perguntar e quais regras são inegociáveis.

## O que um bom `CLAUDE.md` tem

### 1. Postura antes de código

A seção mais importante não é técnica. O `CLAUDE.md` do projeto de referência abre com:

> **Não presuma. Não esconda dúvidas. Exponha os trade-offs.**
>
> - Declare suas suposições de forma explícita. Em caso de incerteza, pergunte.
> - Se houver mais de uma interpretação, apresente-as — não escolha silenciosamente.
> - Se existir uma abordagem mais simples, diga. Questione quando fizer sentido.
> - Se algo estiver confuso, pare, aponte o que não está claro e pergunte.

Isso muda o comportamento do agente em toda decisão ambígua — de "escolher e seguir" para "expor e alinhar".

### 2. Regras objetivas e verificáveis

Regra vaga ("escreva código limpo") não muda comportamento. Regra objetiva sim:

- **Convenção de `data-testid`**: kebab-case, ação por último (`submit-button`, não `button-submit`), nunca valor dinâmico, único por tela, só em elementos críticos — com exemplos ✅/❌ em código.
- **Fluxo de branches em tabela**: de onde cada tipo nasce, para onde abre PR, o que recebe merge. O agente consulta a tabela em vez de adivinhar.
- **Canal único de data fetching**: "toda chamada nova segue o padrão do serviço vizinho" — aponta o diretório e o padrão, não descreve abstratamente.

Cada regra dessas é **checável num diff**: um reviewer (humano ou agente) consegue dizer objetivamente se foi violada.

### 2b. Válvulas de escape nomeadas, com justificativa obrigatória

Todo gate tem um escape hatch (`# noqa`, `eslint-disable`, `@ts-expect-error`, `--no-verify`, `testPathIgnorePatterns`) — e um agente pressionado a "fazer o check passar" vai encontrá-lo. O contrato não finge que a válvula não existe: **nomeia cada uma e exige comentário com o porquê** ao lado do uso — regra checável por lint. Complementos da mesma família:

- **Cláusula anti-cosmética**: quando um gate reprovar, a instrução é repensar a causa ("repense a forma dos dados"), não reescrever até o gate calar. Satisfazer o gate sem satisfazer a intenção é gaming — e o agente faz isso por default se ninguém proibir.
- **Gate aponta, doc de remediação orienta**: o check diz *o que* violou; um doc curto diz *como escolher* a correção (um fluxograma de decisão, não prosa). Sem ele, a "correção" degenera na cosmética acima.
- Pisos são pisos: "cobertura ≥ 80%" acompanha "nunca *reduzir* cobertura" — senão o piso vira teto.

### 3. Gotchas com o porquê

Gotcha sem contexto vira superstição; com contexto, vira conhecimento transferível:

- "Nunca tocar na pasta `drizzle/`" + o porquê (quebra as migrations).
- "`isInternetReachable` pode retornar `false` com rede ativa — não use para gating de lógica crítica."
- Padrões de performance com o código do erro e do acerto lado a lado (ex.: `keyExtractor` estável, paginação em query, busca no blur e não por keystroke).

### 4. Ponte para o humano

O `README.md` ganha uma seção **"Desenvolvendo com IA"** explicando à equipe: o que o `CLAUDE.md` é, quais comandos de projeto existem (`/task`), como as skills chegam na máquina de cada dev e quais plugins instalar. O contrato do agente e o onboarding do humano apontam um para o outro.

### 5. `AGENTS.md`: o mesmo contrato para qualquer agente

`AGENTS.md` é o padrão neutro de arquivo de contexto (aberto pela OpenAI em 2025, hoje sob a Agentic AI Foundation da Linux Foundation; lido por Codex, Cursor, Copilot, Jules, Gemini CLI e afins). A prática free é uma linha:

```bash
ln -s CLAUDE.md AGENTS.md   # versionado — um contrato, N agentes
```

O `CLAUDE.md` continua sendo a fonte única; o symlink só dá o nome padrão que os outros agentes procuram. **Nunca duplique o conteúdo em dois arquivos** — contratos duplicados divergem em silêncio, e cada agente passa a operar sob regras diferentes ([doc 13](13-evidencias-da-literatura.md) tem a evidência de que arquivo de contexto ruim é pior que nenhum).

## Exceções documentadas, não escondidas

Quando o trabalho precisou fugir da convenção (um PR de tooling apontando `task/*` direto para `master`, fora do fluxo padrão), a exceção foi **declarada no corpo do PR** com a justificativa e o registro explícito de que a convenção não mudou:

> Este PR aponta `task/<id>` **direto para `master`**, o que foge da convenção do `CLAUDE.md` (...). Exceção **intencional e pontual**: é trabalho de tooling/config (`chore`), sem código de app (...). Decisão registrada aqui a pedido; a convenção não foi alterada.

A alternativa — quebrar a regra em silêncio — corrói o contrato: se o agente vê exceções não explicadas no histórico, aprende que as regras são opcionais.

## Anti-padrões

| Não faça | Porquê |
|---|---|
| `CLAUDE.md` gigante com prosa genérica | O agente carrega tudo a cada sessão; sinal se dilui em ruído |
| Regras sem exemplo de código | "Use bons nomes" não é verificável; um ✅/❌ é |
| Documentar o que o código já mostra | Estrutura de pastas muda; deixe o mapa mínimo e aponte referências vivas |
| Regra sem porquê | Vira carga cognitiva morta; com porquê, o agente generaliza para casos novos |

**Fonte**: `CLAUDE.md` e `README.md` do app mobile do estudo de caso (entrega E5 — [doc 07](07-licoes-aprendidas.md)).
