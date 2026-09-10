# Installing Video Cuts

Ten minutes, one command, and a phone line. Written for someone who has never
seen this repo.

## What you need

- **A Mac** (Apple Silicon or Intel) with [Homebrew](https://brew.sh)
- **[Plow Latch](https://plow.co/download/latch)** installed and paired with your
  Plow account — this is how the agent reaches your Mac, with your approval
- **Docker Desktop** running
- **Xcode command line tools** are optional: with them the vertical crop follows
  your face; without them it centres, and the agent tells you so

## 1. The Mac side — one command

```sh
git clone https://github.com/gilvanecesar/video-cuts.git && cd video-cuts
sh mac/install.sh
```

This installs `ffmpeg-full` and `whisper-cpp` through Homebrew, downloads the
transcription model (465MB, once) and three fonts, builds the face finder, and
puts `plowcut` in `~/.dailies/bin`. It is idempotent: run it again and it does
nothing. When it finishes it prints a checklist; every line should say `✓`.

If one does not, the same line says how to fix it. `~/.dailies/bin/plowcut
status` prints that checklist any time.

## 2. The phone line

```sh
git clone https://github.com/plow-pbc/plow-agents.git ../plow-agents
export PATH="$PWD/../plow-agents/bin:$PATH"
plow-agents login --new-line
```

It prints a short code and a phone number. **Text that code to that number from
the phone you want the agent bound to** — iMessage works from a Mac too, with no
iPhone. The login command finishes on its own when the text arrives.

```sh
plow-agents lines          # shows your lines; pick one marked free
plow-agents mint ln_xxx    # writes ./plow-credentials (never commit this file)
docker compose up --build -d
```

First build takes a few minutes. Watch it come up:

```sh
docker compose logs -f agent
```

When you see `plow-init: configured ... as cht_`, it is alive. Text the line
and say hello.

## 3. The first recording

Drop a video in `~/Movies/Dailies/`, or text the agent a YouTube link. Then
wait — it texts you when it has something to decide.

**The first time, Latch will ask you to approve what the agent does on your
Mac.** Each prompt names one thing — run `plowcut`, read the intake folder,
open YouTube Studio. Click **Always Allow** (not "Allow Once"): each approval
is remembered, so a full first run asks about nine times and later runs ask
nothing at all. Every command the agent runs is `plowcut` with a single fixed
word, which is what makes those approvals stick.

## 4. Publishing

When you approve a clip with 👍, the agent uploads it through **your own
browser session**. The first time, it opens a visible window at the Google
sign-in and waits for you to log in yourself — it never sees your password.
Or add your Google account to the Latch vault first, and it signs in for you
with `fill_secret`, which types the credential without ever returning it.

Nothing is published without an explicit yes in the thread, about that clip.

## Something is off?

- `plowcut status` — what is missing, and the fix for each
- `docker compose logs agent` — the agent's own log
- `docker compose down -v && docker compose up --build -d` — fresh start; this
  wipes the agent's memory of past conversations, not your clips or index
- Recordings in `~/Movies/Dailies`, clips in `Cortes/`, finished originals in
  `Prontos/`, everything the agent knows in `~/.dailies/`

## Without a Mac

Deploy the cloud image from the agent's page on the Agent Index and text it a
link. Transcription and cutting happen in the container; the clip comes back
in the thread. Face framing and YouTube publishing need the Mac path.
