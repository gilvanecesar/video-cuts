# Dailies

**You finish recording and walk away. By the time you look at your phone, the
thinking is done and one decision is waiting.**

Dailies is a Hermes agent with its own phone number. It watches the folder your
recordings land in, transcribes them on your own Mac, finds the moments that
stand on their own, and texts you the angles to choose from. You answer with one
word. It cuts, and asks before anything goes public.

Your footage never leaves your machine. A two-hour recording is not something to
upload to somebody's cloud, and it does not have to be: the agent reaches into
your Mac through [Plow Latch](https://plow.co/latch), runs your own `ffmpeg` and
`whisper.cpp` there, and only the transcript ever crosses the wire.

## Why it needs a phone line

The gap between "I stopped recording" and "this is published" is hours, and you
spend them somewhere else. A tool you have to open cannot help you there. An
agent with a number can: it starts on its own, and it finds you with the one
call that is actually yours to make — which angle, and whether to publish.

## Requirements

- macOS with [Plow Latch](https://plow.co/download/latch) installed and paired
- Docker
- On the Mac: `ffmpeg` and `whisper-cli` (`brew install ffmpeg whisper-cpp`)
- A Whisper model at `~/.dailies/models/ggml-base.en.bin`

## Install

```sh
git clone https://github.com/<you>/dailies.git && cd dailies
install -m 0755 mac/plowcut ~/.dailies/bin/plowcut
mkdir -p ~/Movies/Dailies

export PATH="$PWD/../plow-agents/bin:$PATH"
plow-agents login --new-line     # text the code it prints
plow-agents lines                # pick a free line
plow-agents mint ln_xxx
docker compose up --build -d
```

Watch `docker compose logs -f agent` until `plow-init: configured ... as cht_`
appears, then text the line and say hello.

## How it is put together

The agent thinks in a container; the work happens on your Mac. Between them sits
Latch, which approves each reach.

```
your phone  ──iMessage──▶  Plow line  ──▶  Hermes agent (Docker)
                                              │
                                          Latch (approved)
                                              ▼
                                        your Mac: plowcut
                                     ffmpeg · whisper.cpp · your files
```

Every command the agent runs on your Mac is `plowcut` with one fixed word and no
arguments — `ready`, `transcribe`, `cut`. That is deliberate. Latch keys your
standing approval on the exact command line, so anything that varied would ask
you again for every recording, forever. `plowcut` is what knows which file is
new; the agent never names it.

## What it will not do

- Publish anything without you saying yes. A 👍 is a yes; silence is not.
- Upload your footage anywhere. Transcription is local.
- Tell you a number it did not count. With no view history, it says it has none
  rather than guessing, and it never dresses a trend index up as an audience.

## Licence

MIT — see [LICENSE](LICENSE).
