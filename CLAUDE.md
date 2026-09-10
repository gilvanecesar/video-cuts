# CLAUDE.md — Dailies (agente Hermes/Plow)

Agente que vigia a pasta de gravações do dono, transcreve no Mac dele, acha os
momentos que se sustentam sozinhos, manda os ângulos por iMessage, corta o que
ele escolher e pede autorização antes de publicar.

**Feito para o Hermes Hackathon** (Plow + AI Worth Using) — entrega **22/09/2026**,
ranking por **instalações e uso**, top 10 vai a voto da equipe Plow em 23/09.
Requisitos: repo público MIT · instalável pelo Agent Index · usar ferramenta
open-source da Plow · integrar o client de tracking. Contexto completo do
hackathon: `../BRIEFING.md`.

## Definição de produto — corte é highlight POR ASSUNTO

Definido pelo dono (09/09). Não é "os N trechos mais fortes" em ranking solto:
é **segmentar a gravação em temas primeiro, e tirar o melhor momento de cada
tema**. O título nasce do assunto, não da frase.

Desdobramento a perseguir: indexando tema por gravação, o acervo acumula e o
corte passa a atravessar episódios ("você já falou de preço 4 vezes; este é o
melhor trecho"). É o que faz o valor **crescer** com o uso.

O `plan.json` ganha o tema:

```json
{"source": "ep-42",
 "clips": [{"topic": "pricing", "title": "...", "start": 412.0, "end": 468.5}]}
```

A máquina de corte não muda — recebe `{start, end, title}` e é agnóstica.

## Arquitetura

O agente **pensa** num container; o trabalho **acontece** no Mac. Entre os dois
está o Latch, que aprova cada alcance.

```
iMessage → linha Plow (Aspen +1 650 315 6335) → Hermes em Docker
                                                     │  Latch
                                                     ▼
                                        Mac: ~/.dailies/bin/plowcut
                                        ffmpeg · whisper.cpp · arquivos
```

## ⚠️ As armadilhas (todas custaram tempo, todas verificadas no código-fonte)

**1. `ruleKey` do Latch hasheia o argv inteiro.** Em
`packages/protocol/src/capability.ts`, `normalizedCapability()` canonicaliza
`paths`, `cwd`, `origins` e `items` — **e não toca em `argv`**. Logo
`ffmpeg -i ep-42.mov` e `ffmpeg -i ep-43.mov` são permissões diferentes, e a
segunda para pra pedir aprovação.
→ **Regra nº 1 do projeto:** todo comando é `plowcut <palavra>`, sem argumento.
O que varia mora em estado (`~/.dailies/state.json`) ou em arquivo de caminho
fixo (`~/.dailies/plan.json`). Caminhos declarados são **pastas**, nunca
arquivos. É por isso que a skill de referência da Plow insiste que o argv do
`plow-gog` seja *"byte-identical every run"*.

**2. Comando silencioso morre aos 15 minutos.** Sem `write_paths` e sem
`network`, o Latch mata o processo se ele não produzir saída nenhuma em 15 min —
e transcrição longa é exatamente isso. Declarar `write_paths` desliga o kill.
O `plowcut` também imprime progresso em stderr pelo mesmo motivo.

**3. `ffmpeg` do Homebrew (9.0.1) não tem `libass` nem `freetype`.** O filtro
`subtitles` não existe e `drawtext` também não. Por isso **não queimamos
legenda** — a plataforma gera a dela, e depender de build customizada quebraria
a instalação em qualquer Mac comum. Decisão do dono, e ela matou o maior risco
de instalação do projeto.

**4. Editar `SOUL.md` exige `docker compose down -v`.** Só `down` mantém o
volume e o agente continua com a persona velha. Pegadinha nº 1 do dia a dia.

**5. Python do python.org não tem CA bundle.** Deu `CERTIFICATE_VERIFY_FAILED`
no `plow-agents login`. Conserto: rodar `/Applications/Python 3.13/Install
Certificates.command`. Vale também pro `agent_index_client.py`, que é o
registro obrigatório no Agent Index.

**6. A imagem base é amd64** e roda emulada no M4. Não importa: o peso (ffmpeg,
whisper) roda nativo no Mac via Latch. Mas se o agente parecer lerdo, a causa é
essa, não o código.

## Comandos

```sh
# subir / reconstruir  (down -v obrigatório se SOUL.md mudou)
docker compose down -v && docker compose up --build -d
docker compose logs -f agent      # espera 'plow-init: configured ... as cht_'

# CLI da Plow (repo em ../ref/plow-agents)
export PATH="$PWD/../ref/plow-agents/bin:$PATH"
plow-agents lines | mint <ln_> | rotate | revoke

# lado Mac
~/.dailies/bin/plowcut {ready|transcribe|cut|status}
```

## Onde as coisas moram

| | |
|---|---|
| entrada | `~/Movies/Dailies/` |
| estado, plano, modelo | `~/.dailies/` |
| trabalho e cortes | `~/.dailies/work/<stem>/clips/` |
| credencial do agente | `./plow-credentials` — **git-ignored, modo 600** |
| repos de referência | `../ref/` (plow-agents, plow-hermes-agent, latch, life-assistant) |

## Estado (09/09/2026)

Funcionando: `ready` · `transcribe` (~27x tempo real, Metal/M4) · `cut`
(1080x1920) · agente no ar respondendo no iMessage com a persona certa.

Pendente:
- **A skill que segmenta por tema e escolhe os momentos** — hoje o plano foi
  escrito à mão. É o coração do produto e ainda não existe.
- Analytics e upload no YouTube via Latch (`plow_browser` + `fill_secret`;
  o `gog` é somente-leitura e não sobe vídeo).
- Registro no Agent Index + serviço s6 do reporter.
- Superfície de instalação: ainda exige `ffmpeg`, `whisper-cli` e modelo de
  141MB no Mac do instalador. O agente precisa checar e guiar isso.
