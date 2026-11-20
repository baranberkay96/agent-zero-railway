#!/bin/bash
# Build-time repair (Railway template). In the v2.16 image the embedding preload
# fails with "All ufuncs must have type numpy.ufunc" (scipy.special sees a numpy
# ufunc class from a different numpy build), which breaks Agent Zero's memory.
# Cause: the image pairs scipy 1.17 (multi-ufuncs such as sph_legendre_p need
# numpy 2) with numpy 1.26. Run upstream's preload; if it fails, install the
# last scipy release that still supports numpy 1.26 cleanly (SCIPY_FALLBACK).
set -uo pipefail
source /opt/venv-a0/bin/activate
site=$(python -c "import sysconfig; print(sysconfig.get_paths()['purelib'])")
echo "fix-numpy: numpy/scipy dist-info: $(cd "$site" && ls -d numpy-*.dist-info scipy-*.dist-info 2>/dev/null | tr '\n' ' ')"

preload_ok() {
	local out
	out=$(cd /git/agent-zero && timeout 900 python preload.py --dockerized=true 2>&1)
	echo "$out" | tail -n 5 | sed 's/^/fix-numpy: preload: /'
	! echo "$out" | grep -q "Error in preload"
}

if preload_ok; then
	echo "fix-numpy: preload works, nothing to do"
	exit 0
fi
version() { find "$site" -maxdepth 1 -type d -name "$1-*.dist-info" -printf '%f\n' | sed -E "s/^$1-(.*)\.dist-info$/\1/" | sort -V | tail -1; }
SCIPY_FALLBACK=1.14.1
echo "fix-numpy: numpy $(version numpy) with scipy $(version scipy) fails; installing scipy $SCIPY_FALLBACK"
for attempt in 1 2 3 4 5; do
	uv pip install --reinstall --no-deps --no-cache "scipy==$SCIPY_FALLBACK" && break
	[ "$attempt" = 5 ] && { echo "fix-numpy: reinstall failed, leaving the image as it was"; exit 0; }
	sleep $((attempt * 10))
done
if preload_ok; then echo "fix-numpy: ok after reinstall"; else echo "fix-numpy: preload still fails (upstream issue, memory features affected)"; fi
exit 0
