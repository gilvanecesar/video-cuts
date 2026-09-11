---
name: dailies-publish
description: Put a finished clip on YouTube — write the title and description, upload it through the owner's own browser session, and record what went out. Use when the owner approves a clip for publishing, asks what is waiting to go up, or asks how something performed.
---

# Video Cuts — publish

## Where each command runs — this matters

The YouTube commands — `yt-connect`, `yt-poll`, `yt-upload`, `yt-stats` — talk
only to Google's API over the network. **Run them inside the container, NOT on
the owner's Mac through Latch.** They touch no file on the Mac, so routing them
through Latch only makes them fail when the owner is away from the keyboard —
which is exactly when they ask how the channel is doing.

Run these with the container's own tools:

```
/opt/dailies/venv/bin/python /opt/dailies/bin/plowcut yt-stats
/opt/dailies/venv/bin/python /opt/dailies/bin/plowcut yt-upload
```

Only the commands that touch the owner's files — `transcribe`, `cut`, `fetch`,
`archive` — go through Latch on their Mac. Everything network-only runs in the
container, so "how is the channel doing?" works with the Mac asleep.

Publishing is the only irreversible thing you do. Everything else can be redone;
a video that went public cannot be unseen. So the rule has no exceptions:

> **Nothing goes online without the owner saying yes, in that message, about
> that clip.** A 👍 is a yes. "Nice" is not. Silence is not. An earlier yes
> about a different clip is not.

If you are unsure whether you have a yes, you do not have one. Ask again.

## What is waiting

```
[PC, "pending"]
```

Clips that exist on disk and have not gone out, with their format and length.
Show them by title, not by path — the owner named these moments and will
recognise them.

## Write the title and description before you ask

Bring them the finished thing to approve, not a chore to complete. A clip they
have to title themselves is a clip that stays on the disk.

**Do not number the title yourself.** `yt-upload` stamps `#1`, `#2`, … on the end in publish order, counting what has gone up before. Write the title clean; the number is added at upload.

**Title** — the hook, not a summary. What made the moment worth cutting should
be readable in the title alone. Short. No colon-subtitle constructions, no
"Veja o que aconteceu". If the moment is a claim, the title is the claim.

**Description** — first line carries; the rest is context. Say what the moment
is, name the fuller recording it came from, and leave the rest alone. Do not
write a paragraph of keywords.

**Tags** — a handful of real ones. Not thirty.

For a vertical clip under three minutes, `#Shorts` in the title or description
is what puts it in the Shorts shelf.

## Connect YouTube once (device flow)

Publishing goes through the YouTube Data API, not a browser — Latch's browser
cannot attach a file, and this is what actually uploads. The owner authorises
their own channel one time, from their phone:

```
[PC, "yt-status"]     already connected? -> {"connected": true}
```

If not connected:

1. `[PC, "yt-connect"]` returns a line like *"Go to google.com/device and
   enter GPX-GLB-LZLH"*. Send that to the owner exactly.
2. Tell them: they will see a "Video Cuts isn't verified" screen — that is
   expected for a new app; **Advanced → continue → allow**. It is their own
   channel they are granting to.
3. When they say done, `[PC, "yt-poll"]`. On `{"connected": true}` you are set
   for every future upload — the token is stored, no browser ever again.

If `yt-poll` times out, they have not finished approving; ask, then poll again.

## Upload — no browser, no file picker

1. Compose the title, description and tags (rules below) and get the owner's 👍
   on them. **Never upload without that yes.**
2. Write `~/.dailies/publish-plan.json` with `plow_write_file`:

   ```json
   {"file": "<clip path from pending>", "title": "...",
    "description": "...", "tags": ["..."], "privacy": "private"}
   ```

   Keep `privacy` as `private`: while the app is unverified the API requires it,
   and it means the owner sees the clip on their channel before the world does.

3. `[PC, "yt-upload"]` — returns `{"url": "https://youtu.be/..."}`. It also
   records the publish against the clip's topic, so `performance` and the index
   know about it. Send the owner the link and tell them it is up as **private**;
   they make it public in one tap, or ask you to (flipping visibility is only a
   click, which the browser can do).

If `yt-upload` errors, say what it said and stop — do not fall back to the
browser uploader, which cannot attach the file.

## Always the absolute path

`PC` is the absolute path you found once (`/Users/.../.dailies/bin/plowcut`).
Use it verbatim — never `~/.dailies/...`. The `~` does not expand inside the
sandbox, the binary is not found, and the owner eats a wasted approval before
you retry with the real path.

## The channel, on demand

When they ask how the channel is doing, how a clip performed, or what is working:

```
[PC, "yt-stats"]
```

Read-only, and it returns **every** video ranked by views — not a page.
Use this for any question about the channel or a video's performance, **never
the browser**: the API is instant, the browser is slow and cannot attach files
anyway. Returns subscribers, total views, and all uploads sorted by views — each with likes, comments and whether it is public or still private.

Answer like someone who watched the numbers, not like a table. Lead with what
changed or what stands out, name the real figures, and — this is the part no
clipping tool can do — cross it with the topic index: if the clips that travel
share a subject, say so. "Your family clips pull about twice the others" is the
sentence worth sending.

If `yt-stats` says the token cannot read the channel, they connected before the
read scope existed: run `yt-connect` again and have them approve once more.

Never invent a number. If a clip is too new to have views, say it has none yet.

## Record it

Once it is up, `yt-upload` has already recorded it. Nothing more to do unless
the owner published a clip some other way — then use the manual `publish` path
below.

## The old manual path (only if the API is not connected and they will not connect)

## Always the absolute path

`PC` is the absolute path you found once (`/Users/.../.dailies/bin/plowcut`).
Use it verbatim — never `~/.dailies/...`. The `~` does not expand inside the
sandbox, the binary is not found, and the owner eats a wasted approval before
you retry with the real path.

## The channel, on demand

When they ask how the channel is doing, how a clip performed, or what is working:

```
[PC, "yt-stats"]
```

Read-only, and it returns **every** video ranked by views — not a page.
Use this for any question about the channel or a video's performance, **never
the browser**: the API is instant, the browser is slow and cannot attach files
anyway. Returns subscribers, total views, and all uploads sorted by views — each with likes, comments and whether it is public or still private.

Answer like someone who watched the numbers, not like a table. Lead with what
changed or what stands out, name the real figures, and — this is the part no
clipping tool can do — cross it with the topic index: if the clips that travel
share a subject, say so. "Your family clips pull about twice the others" is the
sentence worth sending.

If `yt-stats` says the token cannot read the channel, they connected before the
read scope existed: run `yt-connect` again and have them approve once more.

Never invent a number. If a clip is too new to have views, say it has none yet.

## Record it

When they reply with the link, write `~/.dailies/publish.json` with
`plow_write_file`, then:

```
[PC, "publish"]
```

```json
{"file": "<the clip's path from pending>", "url": "<the public URL>",
 "title": "...", "description": "...", "tags": ["..."], "platform": "youtube"}
```

This ties the clip back to the topic it came from, so that weeks later the index
knows not just what was said but what was published from it.

## Later: how it did

```
[PC, "performance"]
```

Views come from you reading YouTube Studio through Latch and writing them into
`publish.json` alongside the clip. Nothing is estimated. **If there is no
reading, say there is none** — an invented number about the owner's own audience
is the fastest way to become useless to them.

When there is real history, use it: say which angle resembles what has worked
before, and name the number you actually read.
