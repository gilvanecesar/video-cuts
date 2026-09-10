#!/usr/bin/env python3
"""yt_upload — put a clip on YouTube through the Data API, no browser, no Mac.

Standard library only, so plowcut stays dependency-free. Uses the OAuth 2.0
Device Flow — the one TVs use — because the owner is on their phone, not at a
keyboard: the agent texts them a short code, they approve at google.com/device,
and every upload after that is silent. No localhost, no redirect, works from the
cloud container as well as a Mac.

    yt_upload.py connect     # start device flow: prints code + url to text
    yt_upload.py poll        # after they approve, exchange for the token
    yt_upload.py upload      # reads ~/.dailies/publish-plan.json
    yt_upload.py status      # connected?

The single client is embedded in the image and shared by every install — a
desktop/limited-input client_secret is not confidential (Google documents this).
Published to Production so tokens do not expire weekly and there is no test-user
allowlist. While the app is unverified, upload lands the video PRIVATE and the
owner flips it public; that is also the approval gate we wanted.
"""
import json, os, sys, time, urllib.parse, urllib.request
from pathlib import Path

HOME = Path(os.environ.get("DAILIES_HOME", Path.home() / ".dailies"))
CLIENT = Path(os.environ.get("YT_CLIENT", HOME / "youtube-client.json"))
TOKEN = HOME / "youtube-token.json"
PENDING = HOME / "youtube-device.json"
SCOPE = "https://www.googleapis.com/auth/youtube.upload"


def _client():
    d = json.loads(CLIENT.read_text())
    d = d.get("installed") or d.get("web") or d
    return d["client_id"], d.get("client_secret", "")


def _post(url, data):
    body = urllib.parse.urlencode(data).encode()
    req = urllib.request.Request(url, body, {"Content-Type": "application/x-www-form-urlencoded"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.load(r), 200
    except urllib.error.HTTPError as e:
        return json.load(e), e.code


def connect():
    if not CLIENT.exists():
        return {"error": "no OAuth client", "fix": f"put it at {CLIENT}"}
    cid, _ = _client()
    d, code = _post("https://oauth2.googleapis.com/device/code",
                    {"client_id": cid, "scope": SCOPE})
    if code != 200:
        return {"error": "device code request failed", "detail": d}
    PENDING.write_text(json.dumps(d)); os.chmod(PENDING, 0o600)
    return {"tell_the_owner": f"Go to {d['verification_url']} and enter  {d['user_code']}",
            "then": "when they say done, run: yt_upload.py poll",
            "expires_in_min": d.get("expires_in", 1800) // 60}


def poll():
    if not PENDING.exists():
        return {"error": "no pending device auth", "fix": "run connect first"}
    cid, secret = _client()
    dev = json.loads(PENDING.read_text())
    deadline = time.time() + min(dev.get("expires_in", 600), 600)
    interval = max(2, dev.get("interval", 5))
    while time.time() < deadline:
        tok, code = _post("https://oauth2.googleapis.com/token", {
            "client_id": cid, "client_secret": secret,
            "device_code": dev["device_code"],
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code"})
        if code == 200 and "refresh_token" in tok:
            TOKEN.write_text(json.dumps(tok)); os.chmod(TOKEN, 0o600)
            PENDING.unlink(missing_ok=True)
            return {"connected": True}
        err = tok.get("error")
        if err == "authorization_pending":
            time.sleep(interval); continue
        if err == "slow_down":
            interval += 2; time.sleep(interval); continue
        return {"error": err or "device flow failed", "detail": tok}
    return {"error": "timed out waiting for approval",
            "note": "they may not have approved yet — run poll again"}


def status():
    return {"connected": TOKEN.exists(),
            "pending": PENDING.exists(),
            "client_present": CLIENT.exists()}


def _access_token():
    cid, secret = _client()
    saved = json.loads(TOKEN.read_text())
    tok, code = _post("https://oauth2.googleapis.com/token", {
        "client_id": cid, "client_secret": secret,
        "refresh_token": saved["refresh_token"], "grant_type": "refresh_token"})
    if code != 200 or "access_token" not in tok:
        raise RuntimeError("refresh failed: " + json.dumps(tok)[:200])
    return tok["access_token"]


def upload():
    if not TOKEN.exists():
        return {"error": "not connected", "fix": "run: yt_upload.py connect"}
    plan = json.loads((HOME / "publish-plan.json").read_text())
    f = Path(plan["file"])
    if not f.exists():
        return {"error": f"clip not found: {f}"}
    import http.client, ssl
    meta = {"snippet": {"title": plan["title"][:100],
                        "description": plan.get("description", ""),
                        "tags": plan.get("tags", [])[:15], "categoryId": "22"},
            "status": {"privacyStatus": plan.get("privacy", "private"),
                       "selfDeclaredMadeForKids": False}}
    token = _access_token()
    size = f.stat().st_size
    ctx = ssl.create_default_context()
    c = http.client.HTTPSConnection("www.googleapis.com", timeout=120, context=ctx)
    c.request("POST",
              "/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status",
              json.dumps(meta).encode(),
              {"Authorization": "Bearer " + token, "Content-Type": "application/json",
               "X-Upload-Content-Type": "video/mp4",
               "X-Upload-Content-Length": str(size)})
    r = c.getresponse(); r.read()
    if r.status not in (200, 201):
        return {"error": f"could not start upload ({r.status})"}
    path = r.getheader("Location").split("googleapis.com", 1)[1]
    print(f"[yt] uploading {size//1024}KB", file=sys.stderr, flush=True)
    put = http.client.HTTPSConnection("www.googleapis.com", timeout=600, context=ctx)
    put.request("PUT", path, f.read_bytes(),
                {"Authorization": "Bearer " + token, "Content-Type": "video/mp4",
                 "Content-Length": str(size)})
    pr = put.getresponse(); data = pr.read()
    if pr.status not in (200, 201):
        return {"error": f"upload failed ({pr.status})",
                "body": data[:300].decode("utf8", "replace")}
    vid = json.loads(data)["id"]
    return {"uploaded": vid, "url": f"https://youtu.be/{vid}",
            "privacy": meta["status"]["privacyStatus"]}


CMDS = {"connect": connect, "poll": poll, "upload": upload, "status": status}
if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] not in CMDS:
        print(json.dumps({"error": "usage: yt_upload.py {connect|poll|upload|status}"})); sys.exit(2)
    try:
        print(json.dumps(CMDS[sys.argv[1]](), indent=2))
    except Exception as e:
        print(json.dumps({"error": str(e)[:300]})); sys.exit(1)
