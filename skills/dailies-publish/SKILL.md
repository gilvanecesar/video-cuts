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

## Upload — you do this alone

Latch's browser cannot attach a file to a page: `fill` on an `<input
type=file>` times out, always. What it *can* do is click "Select files", which
opens the Mac's own file picker — and the picker is a system dialog, which is
exactly what `plow_run_applescript` with **System Events** is for. So the upload
is three tools in a row, and none of them needs the owner at the keyboard.

Verified on 2026-09-10: five `fill` timeouts trying it the wrong way, and a
20-minute loop the owner had to watch. Do not repeat that.

1. **Stage the path.** Write the clip's full path — exactly as `pending`
   printed it — as a single line to `~/.dailies/upload.txt` with
   `plow_write_file`. The AppleScript reads the path from this file so that
   the script itself never changes: Latch keys its standing approval on the
   whole script text, and a script with a path baked in would ask the owner
   again for every clip.

2. **Open a visible browser** (`plow_browser_open` with the headed option) on
   `studio.youtube.com`. Headless has no window for a picker to appear in. If
   it lands on Google sign-in, use the vault with `fill_secret`; with no vault
   item, tell the owner the window is open and wait for them to sign in once.

3. **Click "Create → Upload videos" and then "Select files"** in the upload
   dialog. Screenshot first, then click by selector or coordinates. The Mac
   file picker opens over the browser window.

4. **Drive the picker** with `plow_run_applescript`, `app: "System Events"`,
   and this script — verbatim, character for character, every time:

   ```applescript
   set p to POSIX path of (path to home folder) & ".dailies/upload.txt"
   set thePath to read POSIX file p as «class utf8»
   if thePath ends with linefeed then set thePath to text 1 thru -2 of thePath
   tell application "System Events"
     delay 0.5
     keystroke "g" using {command down, shift down}
     delay 0.7
     keystroke thePath
     delay 0.5
     keystroke return
     delay 0.9
     keystroke return
   end tell
   ```

   ⌘⇧G opens "Go to folder", the path selects the file, the second Return
   confirms. Studio starts uploading immediately.

5. **Fill the details.** Title and description are ordinary text boxes; use
   `forms` to find them and `fill` to set them. Choose "No, it's not made for
   kids" if asked. Screenshot after each step — a click that reported success
   and changed nothing is usually a covered element.

6. **Ask.** Show the owner the title and description and wait for 👍. Not
   before this point, and not without it.

7. **Publish.** Next through the steps to Visibility, choose Public, click
   Publish. Take the URL from the confirmation dialog.

If the AppleScript comes back with an error mentioning accessibility or
"not allowed to send keystrokes", the Mac has not granted Accessibility to
Plow Latch: tell the owner to turn it on in System Settings → Privacy &
Security → Accessibility, then retry the picker step only.

If any step fails twice, stop. Send the clip file into the thread with the
title, description and tags as text, say what failed, and ask them to drop it
into Studio and send you the link. Ten seconds of their time beats a third
attempt.

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
