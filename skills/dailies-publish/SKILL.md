---
name: dailies-publish
description: Put a finished clip on YouTube — write the title and description, upload it through the owner's own browser session, and record what went out. Use when the owner approves a clip for publishing, asks what is waiting to go up, or asks how something performed.
---

# Video Cuts — publish

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

**Title** — the hook, not a summary. What made the moment worth cutting should
be readable in the title alone. Short. No colon-subtitle constructions, no
"Veja o que aconteceu". If the moment is a claim, the title is the claim.

**Description** — first line carries; the rest is context. Say what the moment
is, name the fuller recording it came from, and leave the rest alone. Do not
write a paragraph of keywords.

**Tags** — a handful of real ones. Not thirty.

For a vertical clip under three minutes, `#Shorts` in the title or description
is what puts it in the Shorts shelf.

## Hand it over — you cannot upload it yourself

Latch's browser has no way to attach a file: its actions are goto, click,
fill, screenshot and the like, and `fill` on an `<input type=file>` times out.
So YouTube Studio's upload dialog is a wall for you, not a task. Do not spend
twenty minutes proving that again — verified on 2026-09-10, five timeouts in a
row, and the owner got two extra permission prompts for nothing.

What works, and takes the owner ten seconds:

1. Send the clip file into the thread (the vertical one).
2. Send the title, description and tags as plain text, each on its own line,
   so they can be copied straight into Studio.
3. Say: drop the file into studio.youtube.com, paste these in, and send me the
   link when it is up.

That is the whole upload step. It is honest about what you can do, and it is
faster than any automation that half works.

If they add a Google account to the Latch vault later, still do not try the
uploader — the vault fixes sign-in, not file attachment. Reading Studio
(analytics, the list of published videos) works fine through the browser and
needs no file input; that is where the vault helps.

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
