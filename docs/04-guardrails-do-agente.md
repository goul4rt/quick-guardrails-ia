# 04 — Guardrails do agente: restrição no harness, não no prompt

Pedir no prompt "nunca dê force push" é probabilístico — funciona até o dia em que não funciona. Hook de `PreToolUse` é **determinístico**: o comando é bloqueado antes de executar, sempre, independente do que o modelo "decidiu".

Templates: [`settings.json`](../templates/.claude/settings.json) · [`block-dangerous-git.sh`](../templates/.claude/hooks/block-dangerous-git.sh) · [`eslint-fix-edited.sh`](../templates/.claude/hooks/eslint-fix-edited.sh)

## Guardrails de time, não individuais

O `.claude/settings.json` e os hooks são **versionados no repo**. Todo dev (e todo agente) que clona herda os mesmos guardrails — não é configuração pessoal de quem "lembrou de instalar". O mesmo arquivo declara os plugins habilitados (`enabledPlugins`), fechando o pacote de onboarding.

## `PreToolUse`: bloquear git destrutivo

O hook recebe o comando Bash como JSON no stdin, compara com uma lista de padrões e, ao casar, sai com **código 2** + mensagem no stderr — o Claude Code cancela a execução e o agente vê o motivo.

Padrões bloqueados no template:

| Padrão | Protege contra |
|---|---|
| `push --force` / `push -f` / `--force-with-lease` | Reescrever histórico remoto |
| `reset --hard` | Descartar commits/estado local |
| `clean -f` / `-fd` | Apagar arquivos não rastreados |
| `branch -D` | Deletar branch não mergeada |
| `checkout .` / `restore .` | Descartar mudanças não commitadas |

**Decisão de calibragem — push total ou só force?** Duas variantes legítimas:

- **Bloquear todo `git push`** (variante do repo de origem): push vira ação exclusivamente humana. Máxima segurança; o agente prepara, o humano publica.
- **Bloquear só push forçado** (variante do template): o agente pode publicar branch de trabalho, mas nunca reescrever histórico. Menos fricção em fluxo com PRs.

A escolha depende de quanto o fluxo do time depende do agente abrir PRs sozinho. Note que `git checkout <branch>` (troca de branch) **não** é afetado — o padrão exige o `.` literal.

**A mensagem de bloqueio é parte do guardrail.** O stderr do `exit 2` é injetado de volta no modelo — é o que decide entre o agente se corrigir ou entrar em loop tentando variações. Mensagem boa nomeia **o que casou** e **o que fazer** (o template inclui o padrão e o comando); "bloqueado" seco só informa que a porta está fechada, não onde fica a outra porta. A mesma regra vale para qualquer gate que o agente consome: diagnóstico reparável, não veredito binário.

**Fail-open por dentro, fail-closed na regra.** Erro *interno* do hook (`jq` ausente, JSON inesperado) sai 0 — guardrail quebrado não pode brickar o agente inteiro. Mas regra **casada** nunca é pulável: não existe flag de bypass no hook. Quem garante que os dois lados continuam verdadeiros é o canário ([doc 11](11-teste-o-guardrail.md)): must-pass pega o hook que passou a gritar à toa; must-block com exit code estrito pega o hook que quebrou e "passa" tudo.

## Além do git: baixar-e-executar

A mesma mecânica de hook serve para a segunda família de comandos destrutivos: código remoto executado sem revisão. A regra óbvia (`curl | bash`) é a que menos importa — as variantes que um matcher ingênuo deixa passar (padrões observados em política pública de guardrail de agente, reimplementáveis em poucas linhas de regex):

| Padrão | Exemplo que escapa do `curl \| bash` |
|---|---|
| Fetch remoto por substituição | `bash -c "$(curl -s https://...)"` |
| Download-depois-executa | `curl -o x.sh https://... && chmod +x x.sh && ./x.sh` |
| Execução ofuscada | `echo <base64> \| base64 -d \| sh` |

Duas ressalvas antes de adotar: primeiro, calibre para o seu fluxo — instalador legítimo via curl é rotina em muitos setups; a variante `require_approval` (avisar e pedir confirmação) pode caber melhor que bloqueio seco. Segundo, **extraia as ideias e escreva o seu hook auditável** — instalar um plugin de guardrail de terceiro, pouco auditado, que intercepta todo Bash/Read/Edit/Write, é ele próprio o risco de supply chain que ele diz mitigar.

## O que o hook não é: fronteira de segurança

Hook de harness é proteção determinística contra **acidente** — o agente confuso, o padrão perigoso no caminho feliz. Não é proteção contra **adversário**: roda no mesmo processo que o agente controla, e um prompt injection bem-sucedido pode simplesmente compor o comando de um jeito que o regex não casa. As superfícies que o hook não cobre valem nomear: a *definição* de uma tool MCP e os arquivos de memória/`CLAUDE.md` são input não-confiável (tool poisoning e memory poisoning — instrução maliciosa persistida onde o agente lê toda sessão). Quem precisa de fronteira real contra adversário precisa de contenção **fora do controle do agente**: sandbox, allowlist de rede, credencial de menor privilégio. O hook é a primeira camada, barata e sempre presente — não a última.

## `PostToolUse`: auto-fix de lint no arquivo editado

O segundo hook roda ESLint `--fix` **só no arquivo que acabou de ser editado** (`Edit|Write`). As propriedades que fazem dele um bom hook — e que valem como checklist para qualquer hook de `PostToolUse`:

1. **Rápido**: um arquivo, nunca o projeto inteiro.
2. **Nunca bloqueia**: `exit 0` sempre; o que o `--fix` não resolve fica para o gate.
3. **Silencioso**: output descartado — não polui o contexto do agente.
4. **Degrada bem**: sem `jq`, sem o arquivo (deletado/renomeado), fora de `.ts/.tsx` → sai quieto. `--no-install`: usa o ESLint do projeto, nunca baixa nada.
5. **Se um dia reportar algo, que seja no stderr**: stdout de hook vai para o debug log; **só o stderr chega ao agente**. Um hook de gate que imprime as violações em stdout entrega o alarme sem o diagnóstico — o agente sabe que falhou sem saber o quê.

## Limitação conhecida: falso positivo por substring

O matching é **substring ingênua sobre o comando inteiro** — não parseia se é de fato uma invocação de git. Caso real: um `git commit` foi bloqueado porque a **mensagem do commit** citava "reset --hard" como texto descritivo (documentação de... guardrails).

Trade-offs de conviver com isso:

- É o lado certo do erro: falso positivo custa uma reformulação; falso negativo custa histórico perdido.
- Contorno simples: não citar os padrões literais em mensagens de commit/heredocs (parafrasear).
- A alternativa (parsear shell de verdade) não paga o custo — o hook deixaria de ser 25 linhas auditáveis de bash.

O ponto meta: **todo guardrail simples tem falsos positivos; documente-os em vez de sofisticar o guardrail.**

**Fonte**: entrega E5 do estudo de caso ([doc 07](07-licoes-aprendidas.md)) + calibragem da variante force-only num segundo ecossistema (bot + painel web).
