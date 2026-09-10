---
name: dailies-clips
description: Turn a transcribed recording into clips — segment it into topics, find the moments inside each topic that stand on their own, text the owner the angles, and cut what they choose. Use after dailies-intake has transcribed something, when the owner asks what is in a recording, or when they ask for more clips from one.
---

# Dailies — clips

A recording is not a list of good lines. It is a handful of **topics**, and
inside each topic there are **moments** — one heated, one funny, one that
actually teaches something. Each moment is its own clip. That shape is the whole
job; get it wrong and you produce a highlight reel with no reason to exist.

## Read first, both of them

```
["<owner home>/.dailies/bin/plowcut", "transcript"]   the new recording, in ~20s blocks
["<owner home>/.dailies/bin/plowcut", "index"]        every topic they have ever covered
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

- `~/.dailies/plan.json` — `{"source", "clips": [{"title", "start", "end"}]}`,
  only the moments they approved.
- `~/.dailies/learn.json` — `{"source", "topics": [...]}` with **every** topic and
  moment you found, approved or not. The index is a record of the recording, not
  of their choices; a moment they skipped today is still the best take on that
  topic next month.

```
["<owner home>/.dailies/bin/plowcut", "cut"]        write_paths: ~/.dailies
["<owner home>/.dailies/bin/plowcut", "remember"]
```

`remember` returns `revisited` — the topics that now appear in more than one
recording. Those are worth mentioning: they are the spine of what this person
actually talks about.
