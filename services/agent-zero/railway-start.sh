#!/bin/bash
# Agent Zero start (Railway). Validates the login variables, then hands over to
# the image's own initialize.sh (supervisord: web UI, SearXNG, cron, sshd).
#
# Agent Zero reads AUTH_LOGIN / AUTH_PASSWORD from the environment and then from
# /a0/usr/.env, which wins once you save settings in the UI. No deploy-form value
# stops the deploy (STANDARD 8.29): an unusable password locks the login with a
# random one instead of opening the instance.
set -u

log() { echo "[railway-start] $*"; }
warn() { echo "[railway-start] WARNING: $*" >&2; }

user=${AUTH_LOGIN:-}
if [ -z "$user" ] || [ "${#user}" -gt 64 ] || [[ ! "$user" =~ ^[A-Za-z0-9._@-]+$ ]]; then
	warn "AUTH_LOGIN='${user:0:64}' is empty, longer than 64 characters or has characters other"
	warn "than A-Z a-z 0-9 . _ @ -; using 'admin'"
	user=admin
fi
export AUTH_LOGIN=$user

password=${AUTH_PASSWORD:-}
if [ "${#password}" -lt 12 ] || [ "${#password}" -gt 128 ]; then
	warn "AUTH_PASSWORD is empty, shorter than 12 or longer than 128 characters."
	warn "The login is LOCKED with a random password nobody knows. Set AUTH_PASSWORD"
	warn "(12-128 characters) on the Agent Zero service and redeploy to sign in."
	password=$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')
fi
export AUTH_PASSWORD=$password
unset password

data=/a0/usr
mkdir -p "$data"
if ! mountpoint -q "$data" 2>/dev/null; then
	warn "$data is not a mounted volume: chats, memory, settings and files are lost on every redeploy"
fi
if [ -f "$data/.env" ]; then
	if grep -qE '^[[:space:]]*AUTH_LOGIN[[:space:]]*=[[:space:]]*$' "$data/.env"; then
		warn "$data/.env sets an empty AUTH_LOGIN (saved in Settings): the web UI has NO login."
		warn "Set a login in Settings > External services > Authentication, or delete that line."
	elif grep -qE '^[[:space:]]*AUTH_(LOGIN|PASSWORD)[[:space:]]*=' "$data/.env"; then
		log "login saved in Settings ($data/.env) overrides AUTH_LOGIN/AUTH_PASSWORD from Railway"
	fi
fi

limit=$(cat /sys/fs/cgroup/memory.max 2>/dev/null || echo max)
case "$limit" in
'' | max | *[!0-9]*) ;;
*) [ "$limit" -ge 2147483648 ] || warn "memory limit is $((limit / 1048576)) MiB; Agent Zero needs about 2 GB (Hobby plan or higher)" ;;
esac

# Railway's healthcheck and domain use PORT; the UI listens on 80 (fixed upstream).
if [ "${PORT:-80}" != 80 ]; then
	warn "PORT=${PORT} but Agent Zero's web UI listens on 80; set PORT=80"
fi

log "Agent Zero v2.16, login user $AUTH_LOGIN, data in $data"
exec /exe/initialize.sh "${BRANCH:-main}"
