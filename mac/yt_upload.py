#!/usr/bin/env python3
"""yt_upload — put a clip on YouTube through the Data API, no browser.

Standard library only, so plowcut stays dependency-free. OAuth "installed app"
flow: the owner consents once in their normal browser, the refresh token lives
in ~/.dailies/youtube-token.json, and every upload after that is silent.

    yt_upload.py auth        # print the consent URL, wait for the code
    yt_upload.py upload      # reads ~/.dailies/publish-plan.json

A browser cannot attach a file to YouTube Studio (Latch drives Playwright, which
swallows the native picker), so this is the only path that actually uploads.
The Google-imposed catch while the app is unverified: the video lands PRIVATE
and the owner flips it public — which is one click and is also the approval gate
we wanted anyway.
"""
import json, os, sys, time, urllib.parse, urllib.request, http.client, mimetypes, ssl
from pathlib import Path

HOME = Path(os.environ.get("DAILIES_HOME", Path.home() / ".dailies"))
CLIENT = HOME / "youtube-client.json"      # the OAuth client the owner downloaded
TOKEN = HOME / "youtube-token.json"        # refresh token, written by `auth`
SCOPE = "https://www.googleapis.com/auth/youtube.upload"


def _client():
    d = json.loads(CLIENT.read_text())
    d = d.get("installed") or d.get("web") or d
    return d["client_id"], d["client_secret"]


def _post(url, data):
    body = urllib.parse.urlencode(data).encode()
    req = urllib.request.Request(url, body, {"Content-Type": "application/x-www-form-urlencoded"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def auth():
    cid, secret = _client()
    # Loopback redirect is the current installed-app flow; OOB is retired.
    redirect = "http://localhost:8765/"
    url = "https://accounts.google.com/o/oauth2/v2/auth?" + urllib.parse.urlencode({
        "client_id": cid, "redirect_uri": redirect, "response_type": "code",
        "scope": SCOPE, "access_type": "offline", "prompt": "consent"})
    print(json.dumps({"open_in_your_browser": url,
                      "then": "approve, and the code returns here automatically"}))
    # Tiny one-shot server to catch the redirect.
    import socket
    srv = socket.socket(); srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("127.0.0.1", 8765)); srv.listen(1); srv.settimeout(300)
    conn, _ = srv.accept()
    line = conn.recv(65536).decode("utf8", "replace").splitlines()[0]
    code = urllib.parse.parse_qs(urllib.parse.urlparse(line.split(" ")[1]).query).get("code", [""])[0]
    conn.sendall(b"HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n"
                 b"<h2>Video Cuts is connected. You can close this tab.</h2>")
    conn.close(); srv.close()
    tok = _post("https://oauth2.googleapis.com/token", {
        "client_id": cid, "client_secret": secret, "code": code,
        "redirect_uri": redirect, "grant_type": "authorization_code"})
    if "refresh_token" not in tok:
        return {"error": "no refresh token returned", "got": list(tok)}
    TOKEN.write_text(json.dumps(tok))
    os.chmod(TOKEN, 0o600)
    return {"connected": True, "token_at": str(TOKEN)}


def _access_token():
    cid, secret = _client()
    saved = json.loads(TOKEN.read_text())
    tok = _post("https://oauth2.googleapis.com/token", {
        "client_id": cid, "client_secret": secret,
        "refresh_token": saved["refresh_token"], "grant_type": "refresh_token"})
    if "access_token" not in tok:
        raise RuntimeError("refresh failed: " + json.dumps(tok)[:200])
    return tok["access_token"]


def upload():
    if not TOKEN.exists():
        return {"error": "not connected", "fix": "run: yt_upload.py auth"}
    plan = json.loads((HOME / "publish-plan.json").read_text())
    f = Path(plan["file"])
    if not f.exists():
        return {"error": f"clip not found: {f}"}
    meta = {"snippet": {"title": plan["title"][:100],
                        "description": plan.get("description", ""),
                        "tags": plan.get("tags", [])[:15],
                        "categoryId": "22"},
            "status": {"privacyStatus": "private",   # unverified app: must be private
                       "selfDeclaredMadeForKids": False}}
    token = _access_token()
    size = f.stat().st_size
    # Start a resumable session.
    ctx = ssl.create_default_context()
    conn = http.client.HTTPSConnection("www.googleapis.com", timeout=120, context=ctx)
    body = json.dumps(meta).encode()
    conn.request("POST",
                 "/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status",
                 body, {"Authorization": "Bearer " + token,
                        "Content-Type": "application/json",
                        "X-Upload-Content-Type": "video/mp4",
                        "X-Upload-Content-Length": str(size)})
    r = conn.getresponse(); r.read()
    if r.status not in (200, 201):
        return {"error": f"could not start upload ({r.status})"}
    loc = r.getheader("Location")
    # One PUT; small clips do not need chunking. Print progress so Latch does
    # not kill a long, quiet job.
    print(f"[yt] uploading {size//1024}KB", file=sys.stderr, flush=True)
    put = http.client.HTTPSConnection("www.googleapis.com", timeout=600, context=ctx)
    path = loc.split("googleapis.com", 1)[1]
    put.request("PUT", path, f.read_bytes(),
                {"Authorization": "Bearer " + token,
                 "Content-Type": "video/mp4", "Content-Length": str(size)})
    pr = put.getresponse(); data = pr.read()
    if pr.status not in (200, 201):
        return {"error": f"upload failed ({pr.status})", "body": data[:300].decode("utf8","replace")}
    vid = json.loads(data)["id"]
    return {"uploaded": vid, "url": f"https://youtu.be/{vid}",
            "privacy": "private",
            "note": "live but PRIVATE — flip to Public in Studio, or let the agent do it in the browser (that part is only clicks)"}


CMDS = {"auth": auth, "upload": upload}
if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] not in CMDS:
        print(json.dumps({"error": "usage: yt_upload.py {auth|upload}"})); sys.exit(2)
    try:
        print(json.dumps(CMDS[sys.argv[1]](), indent=2))
    except Exception as e:
        print(json.dumps({"error": str(e)[:300]})); sys.exit(1)
