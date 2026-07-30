# 14. Força de teste: cobertura mede execução, não verificação

O gate do [doc 02](02-gate-de-ci.md) prova que a suíte **passa**. Este doc ataca a pergunta seguinte: a suíte **verifica** alguma coisa? Um teste que executa o código sem assert de valor conta 100% de cobertura e pega zero regressão, e suíte gerada por IA tende exatamente a isso: mata 40 a 50% dos mutantes, contra 70 a 85% das escritas por humanos ([doc 13](13-evidencias-da-literatura.md)). Com o agente escrevendo código E teste, o risco é o **ciclo de auto-engano**: o teste herda o ponto cego do código, e os dois concordam em estar errados.

Tudo aqui é OSS, e entra pela regra de admissão do [doc 09](09-custos.md) sem ressalva.

## Onde aplicar: bug silencioso, não "autoria IA"

O critério óbvio, "módulos com lógica de autoria IA", não filtra nada hoje: quase todo módulo de quase todo projeto se qualifica, e a decisão volta a ser gosto. O critério que separa é outro: **módulo cujo bug seria silencioso**. Dinheiro, autenticação, hash, ordenação, parsing. São os lugares onde o teste passa, o produto responde 200 e o erro só aparece quando alguém audita. Numa auditoria real foi exatamente ali que as duas peças abaixo pagaram o custo: um teste de propriedade achou colisão no hash de uma cadeia de auditoria, e um mutante sobrevivente expôs um caractere não tratado num redirect validado, com a linha 100% coberta e nunca verificada.

O inverso também importa: em CRUD, view e cola de integração, as duas peças custam mais do que devolvem.

## Peça 1, mutation testing: o teste do teste

A ferramenta muta o código (troca `>` por `>=`, remove um branch, inverte um retorno) e roda a suíte: teste forte **mata** o mutante (fica vermelho); mutante sobrevivente é comportamento que ninguém verifica. É a métrica honesta de força de suíte, porque cobertura de linha não distingue executar de verificar.

Ferramentas por stack: **Stryker** (JS/TS/C#), **mutmut** (Python), **PIT** (Java; diff-scoped via arcmutate), **cargo-mutants** (Rust).

Adoção em três passos, nessa ordem, porque full run em repo grande custa horas:

1. **Baseline não-bloqueante** nos módulos de bug silencioso: rode uma vez, registre o score. Sem baseline, threshold é chute.
2. **Incremental no PR**: só os arquivos do diff (`--incremental` no Stryker; `--since` no mutmut). Custo típico: minutos, não horas.
3. **Threshold bloqueante só depois do baseline.** A regra do [doc 02](02-gate-de-ci.md) vale: quando ligar o bloqueio, a dívida já foi zerada ou registrada; gate que nasce vermelho treina bypass.

Sinal de decisão (da pesquisa, [doc 13](13-evidencias-da-literatura.md)): **score abaixo de ~60% num desses módulos significa parar de acelerar feature ali e investir em teste**, porque a suíte está aprovando o que não verifica.

> **Gotcha de escopo**: mutation testing só vê os testes que o mutador executa. Apontá-lo para um módulo coberto apenas por testes de integração (que rodam noutra suíte, ou pedem banco e servidor) devolve 0% e parece dívida gigante, quando o problema é escopo errado. Ou traga o módulo para a suíte unitária, ou tire-o do alvo, mas não leia o zero como qualidade.

## Peça 2, property-based testing: o teste que o autor não imaginou

Teste de exemplo fixa entradas que o autor pensou; PBT declara um **invariante** e a ferramenta gera centenas de entradas tentando quebrá-lo. Ao quebrar, **encolhe** o caso até o mínimo reproduzível:

- `decode(encode(x)) === x` para serialização/parsing
- `sort(sort(xs)) === sort(xs)` para idempotência
- `total(split(valor)) === valor`, porque dinheiro nunca some no rateio

Ferramentas: **fast-check** (JS/TS), **Hypothesis** (Python), **jqwik** (Java), **proptest** (Rust).

Onde vale: lógica pura, parsers, transformações de dados, cálculo de dinheiro e datas, exatamente onde o mutante sobrevivente dói. Onde não vale: CRUD fino e UI (o invariante vira reescrita do mock). A evidência ([doc 13](13-evidencias-da-literatura.md)): exemplo e propriedade pegam ~69% dos bugs cada um, **81% combinados**, então são complementares, não substitutos. Contra o ciclo de auto-engano, a propriedade tem uma vantagem estrutural: força o agente a declarar **o que o código deve garantir**, em vez de confirmar o que o código já faz.

## Peça 3, cobertura no código novo, não no repo

Gate de cobertura repo-inteiro pune quem toca módulo legado e deixa PR novo sem teste passar escondido na média. O gate certo mede **as linhas adicionadas no diff**: ~80% delas executadas pela suíte, por PR.

Template: [`diff-coverage.mjs`](../templates/scripts/diff-coverage.mjs) lê o `coverage-final.json` do runner (Vitest/Jest com istanbul/v8) + `git diff --unified=0` contra a base, cruza os dois e reprova abaixo do piso (`DIFF_COVERAGE_MIN`, default 80). Zero dependência, um comando no gate depois do step de testes.

Duas regras herdadas de outros docs:

- **Piso é piso** ([doc 01](01-contexto-do-projeto.md), 2b): 80% no código novo acompanha "nunca reduzir", senão vira teto.
- **Limitação documentada** ([doc 04](04-guardrails-do-agente.md)): arquivo novo sem teste nenhum não aparece no report de cobertura, então o script conta todas as linhas dele como não cobertas (comportamento desejado, e está comentado no código).

## O que este doc NÃO pede

- Mutation full-run bloqueante em todo PR, que é o jeito de matar a adoção no custo de CI.
- PBT em tudo: invariante forçado em código sem invariante natural é ruído.
- Substituir teste de exemplo: os números dizem **combinar**, não trocar.

**Fonte**: números e estudos no [doc 13](13-evidencias-da-literatura.md); prática de adoção incremental alinhada aos docs [02](02-gate-de-ci.md) (dívida antes do bloqueio) e [09](09-custos.md) (free-first).
