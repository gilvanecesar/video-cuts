---
name: dailies-publish
description: Put a finished clip on YouTube — write the title and description, upload it through the owner's own browser session, and record what went out. Use when the owner approves a clip for publishing, asks what is waiting to go up, or asks how something performed.
---

# Dailies — publish

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

## Upload

The upload runs in the owner's own browser through Latch, with their session
already signed in. There is no API key and nothing for them to configure — which
is the whole reason it works on a machine you have never seen.

1. `plow_browser_open` on `studio.youtube.com`, then `screenshot` — always look
   at where you are before acting.
2. If it asks for a sign-in, check `plow_vault` first. Fill with `fill_secret`,
   never by typing a password you read. A 2FA screen with separate digit boxes
   takes `selectors` naming each box in order.
3. Upload the file, set title and description, choose visibility, publish.
4. Screenshot after every navigation. A click that reported success and changed
   nothing is usually a covered element or a refused request — read
   `failed_requests` before retrying.

Never synthesise a click with `eval`; sites detect it and you will be locked out
of the owner's account, not yours.

## Record it

Write `~/.dailies/publish.json` with `plow_write_file`, then:

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
