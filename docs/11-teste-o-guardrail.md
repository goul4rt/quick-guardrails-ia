# 11 — Teste o guardrail: canário por gate

Guardrail também é código — e código sem teste quebra em silêncio. A diferença é que quando um *feature* quebra, alguém reclama; quando um *guardrail* quebra, tudo continua verde e ninguém percebe que a proteção sumiu. O antídoto é barato: **um canário por gate** — casos conhecidamente maus que o gate deve reprovar, e casos bons que deve deixar passar, rodando no CI.

Template pronto: [`test-guardrails.sh`](../templates/scripts/test-guardrails.sh) — canário do hook de git destrutivo ([doc 04](04-guardrails-do-agente.md)).

## A evidência: dois guardrails públicos mortos, ambos verdes

Dois repositórios públicos de "AI guardrails" examinados em jul/2026 — um template de qualidade para Python, um pipeline de "AI-powered DevSecOps" — provam o modo de falha, cada um do seu jeito:

**Caso 1 — o hook que nunca rodou.** O template anuncia "a cada `.py` editado, o gate roda automaticamente". O hook lê uma variável de ambiente que **não existe** no contrato de hooks do Claude Code (o caminho do arquivo chega por JSON no stdin) — a variável vem vazia, o `case` cai no default, imprime "Skipped" e sai 0. O segundo diferencial do mesmo repo, um analisador de criticidade de call graph, tem um parser que **descarta 100% das arestas** (o formato real da saída da ferramenta contém espaços que o parser rejeita) — e gera para sempre um relatório vazio que o `CLAUDE.md` manda o agente consultar. Nenhum dos dois defeitos produz erro. Um fixture ruim com asserção de exit code teria pego os dois no dia um.

**Caso 2 — o pipeline com badge verde e build quebrado.** Num workflow de demonstração, o exit code do build era capturado assim:

```yaml
run: |
  ./gradlew assembleDebug 2>&1 | tee build.log
  echo "exit_code=${PIPESTATUS[0]}" >> $GITHUB_OUTPUT
```

Sem `set -o pipefail`, o status do step é o do `tee` — sempre 0. O `exit_code` capturado **nunca é lido** em lugar nenhum. Resultado: 31 de 38 runs reportando `success` com `BUILD FAILED` no log. O mesmo repo cacheava o veredito do scan de segurança por hash de árvore (o step aparecia como `skipped` — o "scan" era um `cat` de arquivo cacheado), e quando a única checagem determinística que ele teve gerou o primeiro vermelho legítimo (falso positivo de regex), ela foi **deletada 11 minutos depois** — no commit de nome "Run successful pipeline". Ver os anti-padrões relacionados no [doc 02](02-gate-de-ci.md) e [doc 08](08-seguranca-no-gate.md).

Os dois casos têm a mesma anatomia: o guardrail foi instalado, exibido no README — e nunca **provado**. O verde era o do caminho feliz, não o da proteção.

## O mecanismo

Um canário é um teste com dois baldes de fixtures, rodado contra o **gate real** (o mesmo script/binário/hook que roda em produção — nunca uma reimplementação da regra):

- **must-block** — entradas que o gate existe para barrar. Para o hook de git: `git push --force`, `git reset --hard`, as variantes (`-f`, `--force-with-lease`). Falso negativo aqui = o guardrail não guarda nada.
- **must-pass** — as mesmas famílias em forma legítima: `git push` normal (na variante force-only), `git checkout <branch>`, `git branch -d` minúsculo, `git clean -n`. Falso positivo aqui mata a confiança — e a resposta cultural a gate que grita à toa é bypass, não correção. (Foi um falso positivo sem must-pass que levou o caso 2 a deletar a checagem inteira.)

Regras que fazem o canário valer:

1. **Exit code estrito.** Bloqueio é `exit 2` (ou o código contratual do seu gate), não "qualquer não-zero". Crash do hook não é bloqueio — é exatamente a falha que o canário existe para pegar (caso 1: hook quebrado "passando").
2. **Os dois baldes quebram o CI.** Falso negativo em must-block e falso positivo em must-pass são ambos vermelhos. Um canário só de must-block ensina a resolver falso positivo deletando a regra.
3. **Incidente vira fixture.** Todo bypass ou falso positivo real entra como caso novo no mesmo PR que o corrige — o canário é o teste de regressão do processo.
4. **Limitação documentada vira caso fixado.** O falso positivo conhecido do matching por substring ([doc 04](04-guardrails-do-agente.md)) está no template como `expect_block` com comentário: se um dia parar de casar, o comportamento documentado mudou e o doc precisa mudar junto.
5. **Nunca cachear veredito de gate** — cache de dependência e artefato sim; de resultado de checagem, nunca (o step `skipped` do caso 2). Se o custo do gate dói, reduza o escopo (diff-only), não memoize o veredito.

## Parentes do mesmo princípio

- **A coluna "Verificar" do [CHECKLIST](../CHECKLIST.md)** é um canário manual — `echo '{"tool_input":...}' | hook → exit 2` é exatamente um caso must-block. O template automatiza e amplia isso.
- **Drift de docs**: o caso 2 documentava no README um diretório de policies **que nunca existiu em commit algum**. Um check de cinco linhas — extrair caminhos citados em README/`CLAUDE.md` e falhar se algum não existir — impede contrato de contexto apontando para infra fantasma ([doc 01](01-contexto-do-projeto.md)).
- **O `--dry-run` do `/task`** ([doc 06](06-fluxo-de-task.md)): validar o fluxo sem efeito colateral é a mesma disciplina aplicada a processo.

**Limite conhecido do canário**: ele testa a *lógica* do gate, mas não sobrevive à *deleção do step que o invoca* — no bot Node do estudo de caso, um refactor removeu a linha que rodava a suíte e o job ficou verde por meses ([doc 02](02-gate-de-ci.md), terceiro modo de falha). Para esse modo, a defesa é processo, não código: mudança em `.github/workflows/` é PR dedicado, nunca carona em refactor.

**Fonte**: exploração grounded de dois repositórios públicos de guardrails (jul/2026), com execução real dos gates e leitura dos logs de CI — os dois casos acima.
