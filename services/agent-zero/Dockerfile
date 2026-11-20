# Agent Zero for Railway: the official self-contained image (code runs inside
# this container; no Docker socket needed), pinned by tag and index digest, plus
# a start wrapper that turns the web login on and never leaves it open.
FROM agent0ai/agent-zero:v2.16@sha256:0490714bf25bf481ea50d59ead21acec04344cee410a86b4e159908cb92ed8a2

COPY --chmod=0755 railway-start.sh fix-numpy.sh /usr/local/bin/
RUN bash -n /usr/local/bin/railway-start.sh && test -x /exe/initialize.sh \
 && /usr/local/bin/fix-numpy.sh

EXPOSE 80
CMD ["/usr/local/bin/railway-start.sh"]
