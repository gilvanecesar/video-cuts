# CLAUDE.md — Video Cuts (agente Hermes/Plow)

Agente que vigia a pasta de gravações do dono, transcreve no Mac dele, acha os
momentos que se sustentam sozinhos, manda os ângulos por iMessage, corta o que
ele escolher e pede autorização antes de publicar.

**Feito para o Hermes Hackathon** (Plow + AI Worth Using). **Regras atualizadas em
10/09:** não há mais revisão humana — **o ranking decide**, contando instalações
por outras pessoas + uso de tokens. Snapshot final **23/09/2026, 13h PT (17h BRT)**.
#1 leva o Mac Studio, #2 o Mac Mini, top 3 são candidatos ao podcast.
Requisitos: repo público MIT · **estar na seção Verified** (os anfitriões instalam e
rodam o agente) · integrar o Agent Index client. Página do agente:
`aiworthusing.com/agent-index/dailies` (o slug `dailies` é permanente; o nome de
exibição é **Video Cuts**). Repo: `github.com/gilvanecesar/video-cuts`.
Contexto completo: `../BRIEFING.md`.

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

**6. O sandbox do Latch nega a GPU.** O Metal do whisper falha dentro dele
(4,5x mais lento no CPU: 23s vs 103s para 9,5 min) e o Vision do `facefind`
não acha rosto pelo mesmo motivo. O `plowcut` tenta GPU e cai pra CPU sozinho.

**7. O navegador do Latch NÃO anexa arquivo.** As ações do `plow_browser` são
goto/click/fill/screenshot/etc.; não existe `setInputFiles` em lugar nenhum do
código. `fill` num `<input type=file>` dá timeout. Verificado em 10/09 tentando
publicar no YouTube Studio: 5 timeouts, 20 minutos, 2 prompts extras pro dono.
→ O agente **entrega** o corte + título/descrição/tags na thread e o dono
arrasta pro Studio. Ler o Studio (analytics) pelo navegador funciona.
Alternativa futura, opt-in: YouTube Data API com OAuth do próprio dono.

**8. A imagem base é amd64** e roda emulada no M4. Não importa: o peso (ffmpeg,
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
| entrada (caixa de entrada) | `~/Movies/Dailies/` |
| cortes prontos | `~/Movies/Dailies/Cortes/<nome>/` |
| originais já usados | `~/Movies/Dailies/Prontos/` (com marcador e data) |
| estado, plano, modelo | `~/.dailies/` |
| áudio e transcrição | `~/.dailies/work/<stem>/` |
| credencial do agente | `./plow-credentials` — **git-ignored, modo 600** |
| repos de referência | `../ref/` (plow-agents, plow-hermes-agent, latch, life-assistant) |

## Estado (10/09/2026) — funcional ponta a ponta

Pelo iMessage, tudo automático: **corta** (tema→gancho→legenda→ícone→cartela→
quadro reduzido→miniatura, numerado #N), **publica no YouTube** (Data API +
device flow, sem navegador — o navegador do Latch dirige Playwright e NÃO anexa
arquivo), e **lê o canal** (inscritos/views/comentários via youtube.readonly).
Busca no acervo (`search`) responde "onde falei sobre X". Registrado no Agent
Index (slug `dailies`, nome Video Cuts), repo público `gilvanecesar/video-cuts`,
reporter de uso s6 no ar.

Provado hoje: subiu cortes reais (youtu.be/V1s5Qw9v-3M, youtu.be/JuACenFJCx4).
Canal do dono: Gilvane César, 2690 inscritos, 654k views — os 3 vídeos de topo
são "vida de fazendeiro" (o cruzamento tema×desempenho é o diferencial).

### Comandos do plowcut
`fetch · ready · transcribe · transcript · index · remember · search · cut ·
archive · pending · publish · performance · yt-connect · yt-poll · yt-upload ·
yt-status · yt-stats · status`. yt_upload.py (stdlib) faz a parte da API.

### Armadilhas somadas hoje
- **Navegador do Latch = Playwright, sem setInputFiles** → upload por navegador é
  impossível; só a Data API sobe arquivo.
- **Device flow, não loopback** → o dono aprova por celular; casa com iMessage/nuvem.
- **Escopo mínimo** → começou `youtube.upload` (só sobe); `yt-stats` exigiu
  reconectar com `youtube.readonly`.
- **Caminho absoluto sempre** → `~/.dailies/...` não expande no sandbox (exit 71).
- **App OAuth em modo Teste** → só e-mails na allowlist aprovam; publicar em
  produção tira isso e o vencimento de token de 7 dias.
- **Vídeo sobe PRIVADO** enquanto o app não é verificado pelo Google; o dono
  torna público com 1 clique (é também o portão de aprovação).

### Pendente
- Verificação no Agent Index (abre 14/09, requisito pra ganhar).
- Vídeo de demonstração na página (cortado pelo próprio Video Cuts).
- Publicar o app OAuth em produção (tira vencimento de 7 dias).
- Miniatura custom exige CANAL verificado (passo de telefone), separado da
  verificação do app; degrada limpo se não tiver.

## Estado anterior (09/09/2026)

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
