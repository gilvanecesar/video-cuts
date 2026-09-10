# Video Cuts — a Hermes agent that turns recordings into publishable clips.
#
# Pinned by tag AND digest together: the tag names the base commit, the digest
# is what actually resolves. Bump both, never one.
#   base commit: db182f335c727469d7de4eaf25b5d333670b3069  (2026-09-04)
FROM public.ecr.aws/e1h7x4a2/plow-cloud-agents@sha256:bb2308bc96acd564b9ea0e9b8b577f19f39d6bb96173f29761f24297817d38ed

# The Python side of the pipeline, for when there is no Mac underneath. A cloud
# install has no Homebrew and no whisper.cpp, so faster-whisper does the
# transcription and yt-dlp fetches whatever the owner links. Both live in their
# own venv: Debian 13 refuses system installs, and rightly.
RUN /usr/local/bin/uv venv /opt/dailies/venv \
 && /usr/local/bin/uv pip install -q --python /opt/dailies/venv/bin/python \
      faster-whisper yt-dlp \
 && /opt/dailies/venv/bin/python -c "import faster_whisper, yt_dlp"

# Fonts. Icons are a font, not a folder of images: libass renders "smartphone"
# as the glyph, so there is nothing to rasterise and nothing to keep in sync.
RUN mkdir -p /opt/dailies/assets && cd /opt/dailies/assets \
 && curl -fsL -o icons.ttf "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf" \
 && curl -fsL -o Anton.ttf "https://github.com/google/fonts/raw/main/ofl/anton/Anton-Regular.ttf" \
 && curl -fsL -o Inter.ttf "https://github.com/google/fonts/raw/main/ofl/inter/Inter%5Bopsz%2Cwght%5D.ttf"

# The same pipeline both sides. On a Mac it drives whisper.cpp and the owner's
# own ffmpeg through Latch; here it runs in place.
COPY mac/plowcut /opt/dailies/bin/plowcut
RUN chmod 0755 /opt/dailies/bin/plowcut

# The usage reporter, fetched at build from the commit vendor/client.pin names
# and checked against the hash beside it. Fetched rather than committed because
# plow-pbc/agent-index-client owns that file; pinned rather than tracked from a
# branch because this runs inside an agent holding a live credential.
COPY vendor/client.pin /opt/plow/agent-index-client.pin
RUN set -eu; \
    sha="$(sed -n 's/^sha=//p' /opt/plow/agent-index-client.pin)"; \
    want="$(sed -n 's/^sha256=//p' /opt/plow/agent-index-client.pin)"; \
    path="$(sed -n 's/^path=//p' /opt/plow/agent-index-client.pin)"; \
    curl -fsS --max-time 60 -o /opt/plow/agent-index-client.py \
      "https://raw.githubusercontent.com/plow-pbc/agent-index-client/${sha}/${path}"; \
    got="$(sha256sum /opt/plow/agent-index-client.py | cut -d' ' -f1)"; \
    [ "$got" = "$want" ] || { echo "agent-index client is $got, pin says $want" >&2; exit 1; }; \
    chmod 0644 /opt/plow/agent-index-client.py

COPY image/s6-overlay/ /etc/s6-overlay/

# Identity. Root-owned and world-readable: first boot re-asserts root ownership
# and does not touch the mode, so 0600 here would leave an identity the agent
# cannot read.
COPY --chown=0:0 runtime/SOUL.md /var/lib/hermes/SOUL.md
RUN chmod 0644 /var/lib/hermes/SOUL.md

# Capabilities.
COPY --chown=10000:10000 skills/ /var/lib/hermes/skills/
