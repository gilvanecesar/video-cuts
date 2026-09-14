# Privacy Policy — Video Cuts

_Last updated: 2026-09-14_

**Video Cuts** ("the app") is an open-source personal agent that turns your own
recordings into clips and, when you approve it, publishes them to **your own**
YouTube channel. This policy explains what the app accesses and how it is handled.

## Who runs it
Video Cuts runs on **your own machine / your own agent instance**. It is not a
hosted service that collects your data on our servers. The developer contact is
**gilvane.cesar@gmail.com**.

## What the app accesses
- **Your recordings** — transcribed **locally, on your own machine**. Your video
  and audio are **never uploaded to us** or to any third party for processing.
- **Your YouTube account**, only after you explicitly connect it via Google's
  device-flow consent, using these scopes:
  - `youtube.upload` — to upload clips **to your own channel**, only when you
    approve each upload;
  - `youtube.readonly` — to read **your own** channel stats (subscribers, views,
    video list) so the agent can tell you how your channel is doing.
- The app **never** accesses anyone else's account, and it uploads only to the
  channel of the account you connected.

## How your data is stored and shared
- The OAuth token issued to you is stored **per-owner, on your own machine**, and
  **never leaves it**. We do not receive, store, or have access to your token.
- We do **not** sell, rent, or share your data with third parties.
- The app publishes clips **as private by default**; you decide when to make them
  public.

## YouTube API Services
Video Cuts uses **YouTube API Services**. By using it you also agree to the
[YouTube Terms of Service](https://www.youtube.com/t/terms), and your use of data
obtained through the app is subject to the
[Google Privacy Policy](https://policies.google.com/privacy).

## Revoking access
You can revoke the app's access to your Google/YouTube account at any time at
**https://myaccount.google.com/permissions** (Google security settings → Third-party
access). Revoking it stops all uploads and channel reads immediately.

## Changes
This policy may be updated; the "Last updated" date above reflects the current
version. The source lives in the public repository:
https://github.com/gilvanecesar/video-cuts
