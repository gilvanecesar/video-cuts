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
- Homebrew

## Install

```sh
git clone https://github.com/<you>/dailies.git && cd dailies
sh mac/install.sh                # ffmpeg, whisper, model, fonts, face framing
```

`install.sh` is idempotent — run it again and it does nothing. It touches
nothing outside `~/.dailies` and `~/Movies/Dailies` except two Homebrew
formulae, and `plowcut status` afterwards tells you what is missing and how to
fix each thing.

Then give the agent its phone line and start it:

```sh
git clone https://github.com/plow-pbc/plow-agents.git ../plow-agents
export PATH="$PWD/../plow-agents/bin:$PATH"
plow-agents login --new-line     # text the code it prints, from the phone you own
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

## What it does with a recording

1. Notices it, once the file has stopped growing.
2. Transcribes it on your Mac, word by word. Nothing is uploaded.
3. Segments it into topics and finds the moments inside each that stand alone.
4. Texts you the angles. You answer with one word.
5. Cuts vertical and horizontal, framed on your face, opening on the strongest
   line, with captions, icons and panels it chose.
6. Asks before anything becomes public, then uploads through your own browser
   session and remembers what went out.

The topic index is the part a clipping tool cannot have. Those tools see one
upload and forget it. This one knows your whole library — so when a recording
returns to something you covered in March, it says so.

## What it will not do

- Publish anything without you saying yes. A 👍 is a yes; silence is not.
- Upload your footage anywhere. Transcription is local.
- Tell you a number it did not count. With no view history, it says it has none
  rather than guessing, and it never dresses a trend index up as an audience.

## Licence

MIT — see [LICENSE](LICENSE).
