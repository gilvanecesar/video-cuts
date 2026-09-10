# Dailies — a Hermes agent that turns raw footage into publishable cuts.
#
# Pinned by tag AND digest together: the tag names the base commit, the digest
# is what actually resolves. Bump both, never one.
#   base commit: db182f335c727469d7de4eaf25b5d333670b3069  (2026-09-04)
FROM public.ecr.aws/e1h7x4a2/plow-cloud-agents@sha256:bb2308bc96acd564b9ea0e9b8b577f19f39d6bb96173f29761f24297817d38ed

# Identity. Root-owned and world-readable: first boot re-asserts root ownership
# and does not touch the mode, so 0600 here would leave an identity the agent
# cannot read.
COPY --chown=0:0 runtime/SOUL.md /var/lib/hermes/SOUL.md
RUN chmod 0644 /var/lib/hermes/SOUL.md

# Capabilities.
COPY --chown=10000:10000 skills/ /var/lib/hermes/skills/
