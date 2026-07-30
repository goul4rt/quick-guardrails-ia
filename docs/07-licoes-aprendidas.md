# 07. Lições aprendidas: estudo de caso de cinco entregas

Sequência real de cinco entregas num app mobile em produção (React Native) e o que cada etapa ensinou, incluindo o que **não** foi adotado. Números reais; referências internas generalizadas (E1 a E5).

## Linha do tempo

```
E1 (merged)   Gate de CI bloqueante + pins exatos + Dependabot + audit mensal
  └─ registra pendências: 32 vulns conhecidas · secret no APK (escalado)
E2 (merged)   npm audit fix disciplinado: 32 → 13 vulns, sem --force
E3 (fechada)  paths-ignore p/ docs + workflow no-op companheiro
E4 (merged)   Lockfile drift, 3 dias após E1: o gate pega o problema real
E5 (aberta)   Skills por hash + hooks de guardrails + task close com evidência
```

Repare na ordem: primeiro o **gate** (E1), que cria a rede de segurança; só então as mudanças de risco (E2, E4) passam por ela; por fim a camada de agente (E5) opera dentro dela.

## As lições

### 1. O gate se paga em dias, não meses

Três dias depois de E1, o `npm ci` da mainline quebrou (E4) por lockfile dessincronizado, um estado que antes passaria silencioso e explodiria na máquina de alguém (ou no build de release). O gate falhando **era o comportamento correto**: a lição é resistir ao reflexo de "consertar o CI" e perguntar primeiro se o CI não está certo.

### 2. Dívida se zera de uma vez, no PR que liga o bloqueio

213 errors de ESLint e 97 de tsc zerados **no mesmo PR** que criou o gate. A alternativa gradual ("liga warning-only e vamos reduzindo") treina a equipe, e o agente, a ignorar o vermelho. O detalhe que viabiliza: a maior parte da "dívida" era escopo/config (código vendored sem ignore, globals ausentes), não código ruim. Vale a auditoria antes de assumir que zerar é caro.

### 3. Validar contra baseline, não contra ideal

E2 mexeu no lockfile com a suíte de testes **já quebrada** (falhas pré-existentes, rastreadas à parte). O critério de aceite não foi "testes verdes", o que era impossível, e sim "resultado **idêntico** ao baseline". Sem essa disciplina, ou o trabalho trava esperando o mundo perfeito, ou alguém "arruma" teste alheio dentro de um PR de lockfile.

### 4. Required check + skip de workflow = armadilha silenciosa

A pegadinha de E3 (check required + `paths-ignore` = pending eterno) não aparece em teste local nem no PR que a introduz, só quando o primeiro PR só-de-docs trava. O padrão no-op companheiro resolve, ao custo de **dois filtros espelhados para sempre**. A entrega foi fechada sem merge; a otimização é opcional, conhecer a armadilha não é.

### 5. Escopo tem borda, e a borda se registra

Dois exemplos de disciplina de escopo no mesmo pacote:

- Achado de segurança fora do escopo (secret no APK de release) virou **pendência registrada no PR + escalada à gestão**, não correção heroica embutida.
- Fuga da convenção de branches em PR de tooling virou **nota explícita no PR** ("exceção intencional e pontual; a convenção não foi alterada").

Nos dois casos a informação sobrevive: quem ler o PR daqui a um ano entende o que foi decidido e por quê.

### 6. Guardrail simples ganha do guardrail esperto (e seus falsos positivos se documentam)

O hook de git bloqueou um `git commit` legítimo porque a mensagem citava um padrão perigoso como texto. A resposta certa não foi sofisticar o parser: foi documentar a limitação e parafrasear a mensagem. 25 linhas de bash auditáveis com falso positivo conhecido valem mais que 200 linhas "inteligentes" com falso negativo desconhecido.

### 7. Tudo que o agente entrega é verificável por comando

Padrão transversal às cinco entregas: critérios de aceitação escritos como **comandos com saída esperada** (`npm ci --dry-run` passa; `rc != 0` propaga; HTTP 200 no upload), não como prosa ("funciona corretamente"). É o que permite a um humano, ou a outro agente, conferir a entrega sem confiar na palavra de quem entregou.

## Anti-lições (o que este caso NÃO diz)

- **Não diz** que todo repo precisa dos 6 checks; diz que os que existirem devem bloquear.
- **Não diz** que agente deve fazer push/merge sozinho. Aqui, push de task é do fluxo, merge é humano, e uma variante bloqueia até o push.
- **Não diz** que a otimização de docs-only vale a pena; diz o que ela custa.
