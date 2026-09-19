# Video Cuts — a Hermes agent that turns recordings into publishable clips.
#
# Pinned by tag AND digest together: the tag names the base commit, the digest
# is what actually resolves. Bump both, never one.
#   base commit: ef0019372ff8bca593611b31ebd2e08f9f1458ff  (2026-09-18)
FROM public.ecr.aws/e1h7x4a2/plow-cloud-agents:base-ef0019372ff8bca593611b31ebd2e08f9f1458ff@sha256:a8a2f97ad78b8192d80a984dce81d3bf5a9a883d18cb7b677704913a09b56aee

# The Python side of the pipeline, for when there is no Mac underneath. A cloud
# install has no Homebrew and no whisper.cpp, so faster-whisper does the
# transcription and yt-dlp fetches whatever the owner links. Both live in their
# own venv: Debian 13 refuses system installs, and rightly.
# uv downloads its own Python; send it to /opt (world-readable) instead of
# /root, which is 0700 — the agent runs as `hermes` and could not exec a Python
# living under root's home. --python 3.11 pins it; the whole tree ends up under
# /opt/dailies where hermes can read and execute it.
ENV UV_PYTHON_INSTALL_DIR=/opt/dailies/python
RUN /usr/local/bin/uv venv --python 3.11 /opt/dailies/venv \
 && /usr/local/bin/uv pip install -q --python /opt/dailies/venv/bin/python \
      faster-whisper yt-dlp \
 && /opt/dailies/venv/bin/python -c "import faster_whisper, yt_dlp" \
 && HF_HOME=/opt/dailies/models /opt/dailies/venv/bin/python -c \
      "from faster_whisper import WhisperModel; WhisperModel('small', device='cpu', compute_type='int8')" \
 && chmod -R a+rX /opt/dailies/python /opt/dailies/venv /opt/dailies/models

# Fonts. Icons are a font, not a folder of images: libass renders "smartphone"
# as the glyph, so there is nothing to rasterise and nothing to keep in sync.
RUN mkdir -p /opt/dailies/assets && cd /opt/dailies/assets \
 && curl -fsL -o icons.ttf "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf" \
 && curl -fsL -o Anton.ttf "https://github.com/google/fonts/raw/main/ofl/anton/Anton-Regular.ttf" \
 && curl -fsL -o Inter.ttf "https://github.com/google/fonts/raw/main/ofl/inter/Inter%5Bopsz%2Cwght%5D.ttf"

# The same pipeline both sides. On a Mac it drives whisper.cpp and the owner's
# own ffmpeg through Latch; here it runs in place.
# In the cloud the container is root but the agent runs as `hermes`, so a bare
# ~ sends plowcut's state to three different places depending on who calls it.
# Pin one home under the agent's own tree; the Mac install leaves this unset and
# uses the owner's ~/.dailies instead.
ENV DAILIES_HOME=/var/lib/hermes/.dailies
# faster-whisper model cache, pre-populated at build so the cloud
# deploy transcribes immediately instead of pulling from HuggingFace.
ENV HF_HOME=/opt/dailies/models

COPY mac/plowcut mac/yt_upload.py /opt/dailies/bin/
RUN chmod -R a+rX /opt/dailies \
 && chmod 0755 /opt/dailies/bin/plowcut /opt/dailies/bin/yt_upload.py \
 && mkdir -p /var/lib/hermes/.dailies/intake \
 && chown -R 10000:10000 /var/lib/hermes/.dailies

# Identity. The base composes $HOME/SOUL.md on EVERY boot as plow-seed/SOUL.md
# (its base rules) + plow-seed/persona.md (the variant's own), via
# compose_identity() in /etc/s6-overlay/scripts/plow-init.py. So we ship our
# persona as persona.md, NOT as /var/lib/hermes/SOUL.md: that path is under the
# agent-home volume (shadowed at runtime) AND compose_identity overwrites it
# every boot. Composing (not replacing) also keeps the base's voice/judgement/
# Latch-routing rules — replacing the whole SOUL silently dropped them upstream.
# Root-owned, world-readable so init reads it.
COPY --chown=0:0 runtime/SOUL.md /opt/hermes/plow-seed/persona.md
RUN chmod 0644 /opt/hermes/plow-seed/persona.md

# Capabilities.
COPY --chown=10000:10000 skills/ /var/lib/hermes/skills/
