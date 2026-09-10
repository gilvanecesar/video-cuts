---
name: dailies-clips
description: Turn a transcribed recording into clips — segment it into topics, find the moments inside each topic that stand on their own, text the owner the angles, and cut what they choose. Use after dailies-intake has transcribed something, when the owner asks what is in a recording, or when they ask for more clips from one.
---

# Dailies — clips

A recording is not a list of good lines. It is a handful of **topics**, and
inside each topic there are **moments** — one heated, one funny, one that
actually teaches something. Each moment is its own clip. That shape is the whole
job; get it wrong and you produce a highlight reel with no reason to exist.

## The one path you need

Everything below runs on the owner's Mac through Latch, and every command is
`plowcut` with one fixed word and nothing else. Find the binary once:

```
["/bin/sh", "-c", "echo $HOME/.dailies/bin/plowcut"]
```

That argv never varies either, so it costs one approval. Remember the answer —
it is the same for every recording this owner will ever make, and rebuilding it
per call would ask them again. Below, `PC` means that path.

## Read first, both of them

```
[PC, "transcript"]   the new recording, line by line with timestamps
[PC, "index"]        every topic they have ever covered
```

The index is the part no clipping tool has. Those tools see one upload and
forget it. You know the whole library — so when this recording returns to
something they covered in March, say so, and say whether this take is better or
whether it contradicts the old one. That is the sentence nobody else can write.

## 1. Segment into topics

Read the whole transcript before deciding anything. Mark where the conversation
actually turns — not every tangent, the real chapters. A two-hour recording is
usually four to seven topics. Name each one the way the owner would name it, in
their words, and reuse the exact name from the index when it is the same subject
coming back. A topic that gets a new name every episode indexes nothing.

## 2. Find the moments inside each topic

Within a topic, look for the pieces that survive on their own: a claim someone
would argue with, a story with a beginning and an end, a straight answer to an
awkward question, a revelation, something genuinely funny. Give each one a
`kind` — `polemic`, `story`, `revelation`, `funny`, `useful`, `question` — and
expect the strong topics to yield two or three while a weaker one yields none.
Nothing forces every topic to produce a clip.

The test for a moment: **would this make sense to someone who has heard nothing
before it?** If it needs the previous sentence, it is not a moment yet — either
move the start earlier to where it becomes self-contained, or drop it.

## 3. Put the hook first

This is where most clips die. The first seconds decide whether anyone reaches
the end, and roughly seven in ten clips that travel open on a strong question, a
blunt statement, or something unexpected.

So the clip does **not** start where the topic starts. Find the strongest line in
the moment and start there — `hook_at` is that timestamp, and `start` should
normally equal it. A clip that opens with "so, going back to what we were
saying" has already lost.

Length follows the moment, not a rule. Most land between 30 and 60 seconds, but
the thing that actually gets a clip pushed is retention, so a tight 30 that holds
beats a padded 60 that leaks. End on the line that lands, never on a trailing
"...you know?".

## 4. Text the owner

Lead with the angle, never the explanation. They are reading one-handed. For
each: the topic, the kind, the title, and how long it runs. Where the index
shows they have been here before, say it — that is the most interesting sentence
you have.

If they have view history, name what has worked before and give the real number.
If they have none, say so plainly. Never present a trend index as an audience.

## 5. Cut what they choose

Write both files with `plow_write_file`, then run the two commands. Files, never
arguments — the argv has to stay identical or Latch asks them again every time.

- `~/.dailies/plan.json` — the moments they approved:
  `{"source", "clips": [{"topic", "kind", "title", "hook_text", "start", "end",
  "keywords": [{"text", "at"}]}]}`

  Each clip may also carry `effects` — the graphics you choose to put on it.
  This is where a clip stops being a subtitled crop and starts being an edit,
  so choose like an editor: a beat needs a reason, and four graphics in twenty
  seconds is noise, not energy. Two or three per clip is usually right.

  ```
  "keywords": [{"text": "ZERO CELULAR", "at": 439.6, "icon": "smartphone"}]
  "effects": [
    {"type": "punch",       "at": 428.0, "amount": 0.11},
    {"type": "pull",        "at": 450.0},
    {"type": "card",        "from": 453.0, "to": 457.0,
     "title": "SEM TELAS", "sub": "so o que a gente viveu", "icon": "child_care"},
    {"type": "lower_third", "from": 425.0, "to": 429.0, "text": "Gilvane · pai"},
    {"type": "flash",       "at": 441.0}
  ]
  ```

  - **keyword** — a short line that lands on screen the instant it is spoken,
    with an optional icon above it. Make it **condense**, never echo: the
    caption already shows every word, so the same word in large type says
    nothing twice. "13 ANOS" over a man describing thirteen years of school
    runs adds something; "RELIGIOSAMENTE" over the word religiosamente does not.
  - **punch / pull** — the camera lunges in, or opens out. Put a punch where the
    sentence turns, not on a schedule.
  - **card** — a titled panel. Use it to name a thing the speaker only implies.
  - **lower_third** — who is talking, early and briefly.
  - **flash** — one frame of white. Rare, or it is a strobe.

  Icon names come from Material Symbols: plain English nouns and verbs —
  `smartphone`, `school`, `sports_soccer`, `child_care`, `favorite`, `alarm`,
  `attach_money`, `groups`, `home`, `trending_up`. If you are unsure a name
  exists, leave the icon out; a missing glyph renders as a blank box on screen.

  `hook_text` is the sentence the clip must OPEN on, quoted from the transcript;
  `cut` finds that word in the audio and starts there. `keywords` are what lands
  on screen at the instant it is spoken — two per clip, at most. Make them
  **condense**, never echo: the caption already shows every word, so putting the
  same word up in large type says nothing twice. "13 ANOS" over a man describing
  thirteen years of school runs adds something; "RELIGIOSAMENTE" over the word
  religiosamente does not.
- `~/.dailies/learn.json` — `{"source", "topics": [...]}` with **every** topic and
  moment you found, approved or not. The index is a record of the recording, not
  of their choices; a moment they skipped today is still the best take on that
  topic next month.

```
[PC, "cut"]        write_paths: ~/.dailies and the recording's folder
[PC, "remember"]
```

## 6. Put the recording away

Once they have the clips and are done with that recording:

```
[PC, "archive"]
```

It moves the source out of the intake folder into `Cortes/../Prontos`, keeping
its name plus a dated marker, and tells you where the clips are. Nothing is
deleted, and `cut` still finds an archived recording — they can ask for another
clip from it weeks later. Tell them the delivery folder by name; do not make
them go looking.

`remember` returns `revisited` — the topics that now appear in more than one
recording. Those are worth mentioning: they are the spine of what this person
actually talks about.
