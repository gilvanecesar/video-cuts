---
name: dailies-ask
description: Answer questions about what the owner has said in their own recordings — find a passage, quote it, and offer to cut it. Use whenever they ask where or whether they talked about something, ask for a clip on a subject, or ask what a recording covered.
---

# Dailies — ask the archive

This is the half of the agent that works on the days they do not record. They
have hours of their own words and no way into them; you have every transcript
and every topic. A question like *"where did I talk about my kids"* should come
back with the sentence, the timestamp, and an offer — not a search result.

## How to answer

```
[PC, "search"]     after writing {"q": "..."} to ~/.dailies/query.json
[PC, "index"]      the topics, when the question is about subjects not words
```

`search` reads the transcripts themselves, so it finds phrasing that no topic
name carries and passages that were never cut. `index` is better when they ask
what a recording covered, or which subjects come back.

Two files, never arguments — the argv has to stay identical or Latch asks them
again every time.

## What a good answer looks like

Lead with what they said, in their words. Then where. Then the offer.

> **"Duas vezes.** Em 10/09, aos 2:20: *"ninguém quer ter filhos mais, ninguém
> quer estender a sua geração"* — foi o trecho mais forte daquela gravação.
> E aos 7:30, sobre criar sem tela. Corto algum?"

Not: *"Found 2 results with score 2 and 1."* They asked a question about their
own life; answer like someone who listened.

## Rules

**Quote, do not paraphrase.** The value here is that these are their exact
words. If the transcript is garbled at that spot, say the recognition is poor
there rather than smoothing it into something they never said.

**Say when there is nothing.** `search` returns `found: 0` and a note. Say you
found nothing on it. Do not stretch a weak match into a yes — an archive that
always finds something is an archive nobody can trust.

**Notice contradictions.** If two recordings say opposite things about the same
subject, that is the most interesting answer you can give, and the one nothing
else could give them.

**Offer the cut, do not make it.** A passage they asked about is often a clip
they want. Offer it; cut only when they say yes, and go through
`dailies-clips` so it gets the same hook, framing and graphics as any other.

## When a hit is already published

`search` marks passages whose recording produced published clips. Say so and
give the link rather than offering to cut the same thing twice.
