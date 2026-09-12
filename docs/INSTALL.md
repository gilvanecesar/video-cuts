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
nothing. When it finishes it runs `plowcut status`, which should report
`"ready": true` with nothing under `missing`.

If something is missing, each entry names its own fix. Run
`~/.dailies/bin/plowcut status` to check any time.

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
write the finished clip. Click **Always Allow** (not "Allow Once"): each approval
is remembered, so a full first run asks about nine times and later runs ask
nothing at all. Every command the agent runs is `plowcut` with a single fixed
word, which is what makes those approvals stick.

## 4. Publishing to YouTube

Connect your channel once, from your phone, with Google's device flow — no
password ever reaches the agent. Ask the agent to connect YouTube; it texts you
a short code:

```
[agent] "Go to google.com/device and enter WHJ-KKC-WBQD"
[you]   approve on your phone, once
```

After that, when you approve a clip with 👍, the agent uploads it straight to
YouTube through the Data API — no browser, no file picker. It lands **private**;
while the app is unverified it stays private until you flip it public in one tap,
which is also your final consent. Clips are numbered `#1`, `#2`, … in publish
order, each with a thumbnail pulled from the clip itself.

Publishing by browser is not possible — Plow Latch's browser drives Playwright,
which cannot attach a file — so the Data API is the only path that truly uploads.
Reading the channel (subscribers, views, which angle works) is network-only, so
it runs in the container and answers even with your Mac asleep.

## Something is off?

- `plowcut status` — what is missing, and the fix for each
- `docker compose logs agent` — the agent's own log
- `docker compose down -v && docker compose up --build -d` — fresh start,
  needed after editing `runtime/SOUL.md`; this wipes the agent's memory of past
  conversations, but **not** its install identity or your YouTube connection —
  those live in `agent-persist/` (a bind mount) and survive `-v`, so you never
  reconnect just to change the persona. Do not delete or commit `agent-persist/`;
  it holds the token.
- Recordings in `~/Movies/Dailies`, clips in `Cortes/`, finished originals in
  `Prontos/`, everything the agent knows in `~/.dailies/`

## Without a Mac

Once the agent is verified on the Agent Index, its page shows a one-click
**Deploy** button (until then, that button is disabled — the Mac path above
is the way in). After deploying, text it a link. Transcription and cutting happen in the container; the clip comes back
in the thread. Face framing and YouTube publishing need the Mac path.
