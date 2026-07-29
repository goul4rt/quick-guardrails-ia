# 12 — Fronteira: guardrails de desenvolvimento × guardrails de runtime de LLM

"Guardrail" nomeia duas categorias que não se substituem:

- **Guardrails de desenvolvimento** (este repositório): protegem o *processo* de construir software com um agente — hooks de harness, gate de CI, supply chain, fluxo de task. O risco é o agente destruir trabalho, mergear regressão, vazar secret.
- **Guardrails de runtime de LLM**: protegem o *produto* que usa LLM em produção — validar input/output do modelo (moderação, PII, prompt injection vindo de usuário final, formato de resposta). O risco é o seu app dizer/aceitar o que não deve.

Quem constrói produto com LLM precisa dos dois; este repo só cobre o primeiro. Esta página registra o que a exploração da segunda categoria (jul/2026) rendeu — o que transferiu, e onde apontar quem precisa de runtime.

## O que transferiu de lá para cá

- **A taxonomia de resposta ao disparo** (as ações OnFail dos frameworks de runtime) mapeia 1:1 para guardrails de dev — incorporada no [doc 10](10-guardrails-alem-do-ci.md).
- **Mensagem reparável**: um validator de runtime que só diz "falhou" não alimenta correção automática; um hook que só diz "bloqueado" também não — ver [doc 04](04-guardrails-do-agente.md).
- **O case free-first**: os endpoints hospedados "free preview" da categoria morreram com data marcada — evidência da regra de admissão, registrada no [doc 09](09-custos.md).

## Opções OSS para runtime (com as ressalvas verificadas)

Nenhuma entra nos templates (categoria de produto, não de processo). A tabela existe para quem precisar não partir do zero — condições verificadas em fonte primária em jul/2026:

| Opção | Licença | Ressalvas verificadas |
|---|---|---|
| **guardrails-ai** (framework Python; Guard/Validator, 70 validators no hub) | Apache 2.0 (core) | `Guard.parse` com `num_reasks=0` valida **sem chamada de LLM** — esse é o modo free de verdade. Mas: no código, `use_remote_inferencing` e a telemetria (com `user_id`) vêm **ligados por default**, ao contrário do que a doc afirma — desligue explicitamente. Ritmo de commits em modo manutenção; o **Server** é repo separado sob licença derivada da Elastic (não-OSI, cláusula anti-hosted-service). Validators do hub podem chamar API paga por baixo — leia cada um |
| **NeMo Guardrails** (NVIDIA) | Apache 2.0 | O outro nome estabelecido da categoria; rails programáveis sobre o diálogo |
| **OpenGuardrails-Text** (modelo guard, 19 categorias de risco, 119 idiomas) | Apache 2.0 (pesos, não-gated) | Free em licença, **não em infra**: inferência séria pede GPU. O repo GitHub homônimo hoje contém outra coisa (spec de protocolo para guardrails de agente) — os pesos vivem no Hugging Face |
| **Presidio** (Microsoft — detecção/anonimização de PII via NER) | MIT | Peça focada: só PII, roda local |

## O padrão que se repete

A categoria runtime confirma as regras deste repo em outro terreno: o que valida **sem modelo** (regex, schema, parse) é determinístico e free; o que valida **com modelo** custa infra ou token e tem os defaults do vendor apontando para o serviço dele. Verifique o default no código, não na doc — e trate "free preview" como o que é: cortesia com prazo ([doc 09](09-custos.md)).
