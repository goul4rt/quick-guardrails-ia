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

### 3. Gotchas com o porquê

Gotcha sem contexto vira superstição; com contexto, vira conhecimento transferível:

- "Nunca tocar na pasta `drizzle/`" + o porquê (quebra as migrations).
- "`isInternetReachable` pode retornar `false` com rede ativa — não use para gating de lógica crítica."
- Padrões de performance com o código do erro e do acerto lado a lado (ex.: `keyExtractor` estável, paginação em query, busca no blur e não por keystroke).

### 4. Ponte para o humano

O `README.md` ganha uma seção **"Desenvolvendo com IA"** explicando à equipe: o que o `CLAUDE.md` é, quais comandos de projeto existem (`/task`), como as skills chegam na máquina de cada dev e quais plugins instalar. O contrato do agente e o onboarding do humano apontam um para o outro.

## Exceções documentadas, não escondidas

Quando o trabalho precisou fugir da convenção (um PR de tooling apontando `task/*` direto para `master`, fora do fluxo padrão), a exceção foi **declarada no corpo do PR** com a justificativa e o registro explícito de que a convenção não mudou:

> Este PR aponta `task/psq-769` **direto para `master`**, o que foge da convenção do `CLAUDE.md` (...). Exceção **intencional e pontual**: é trabalho de tooling/config (`chore`), sem código de app (...). Decisão registrada aqui a pedido; a convenção não foi alterada.

A alternativa — quebrar a regra em silêncio — corrói o contrato: se o agente vê exceções não explicadas no histórico, aprende que as regras são opcionais.

## Anti-padrões

| Não faça | Porquê |
|---|---|
| `CLAUDE.md` gigante com prosa genérica | O agente carrega tudo a cada sessão; sinal se dilui em ruído |
| Regras sem exemplo de código | "Use bons nomes" não é verificável; um ✅/❌ é |
| Documentar o que o código já mostra | Estrutura de pastas muda; deixe o mapa mínimo e aponte referências vivas |
| Regra sem porquê | Vira carga cognitiva morta; com porquê, o agente generaliza para casos novos |

**Fonte**: [`CLAUDE.md` e `README.md` do instivo-pesquisador-app](https://github.com/Instivo/instivo-pesquisador-app) (PR [#141](https://github.com/Instivo/instivo-pesquisador-app/pull/141)).
