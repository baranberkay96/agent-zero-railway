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

version() { find "$site" -maxdepth 1 -type d -name "$1-*.dist-info" -printf '%f\n' | sed -E "s/^$1-(.*)\.dist-info$/\1/" | sort -V | tail -1; }

preload_ok() {
	local out
	out=$(cd /git/agent-zero && timeout 900 python preload.py --dockerized=true 2>&1)
	echo "$out" | tail -n 5 | sed 's/^/fix-numpy: preload: /'
	echo "$out" | grep -q "Error in preload" && return 1
	# The build-time preload does not reach every runtime import; scipy.special
	# is the module that fails at runtime, so test it directly.
	out=$(python -c "import numpy, scipy.special, faiss; print('numpy', numpy.__version__, 'scipy imports ok')" 2>&1)
	echo "$out" | tail -n 3 | sed 's/^/fix-numpy: import: /'
	echo "$out" | grep -q "scipy imports ok"
}

# Files under numpy/ that numpy's own RECORD does not list are leftovers of
# another numpy release; at runtime some import reaches them and scipy then sees
# two ufunc classes ("All ufuncs must have type numpy.ufunc"). Remove them.
python - "$site" <<'PY'
import csv, glob, os, shutil, sys
site = sys.argv[1]
records = glob.glob(os.path.join(site, "numpy-*.dist-info", "RECORD"))
if len(records) != 1:
    print("fix-numpy: expected one numpy dist-info, found", len(records)); sys.exit(0)
keep = {os.path.normpath(r[0]) for r in csv.reader(open(records[0])) if r}
stray = []
for root, dirs, files in os.walk(os.path.join(site, "numpy")):
    dirs[:] = [d for d in dirs if d != "__pycache__"]
    for f in files:
        rel = os.path.normpath(os.path.relpath(os.path.join(root, f), site))
        if rel not in keep:
            stray.append(rel)
print("fix-numpy: stray numpy files:", len(stray), " ".join(sorted(stray)[:15]))
for rel in stray:
    os.remove(os.path.join(site, rel))
for root, dirs, files in os.walk(os.path.join(site, "numpy"), topdown=False):
    if not os.listdir(root):
        os.rmdir(root)
PY

# The build-time checks pass, yet the runtime preload still fails inside the
# UI process (seen on Railway). scipy >= 1.15 ships the multi-ufuncs that
# trigger it; with numpy 1.x always use the last scipy release without them.
case "$(version numpy)" in
1.*) ;;
*) if preload_ok; then echo "fix-numpy: numpy 2, preload works"; exit 0; fi ;;
esac
SCIPY_FALLBACK=1.14.1
echo "fix-numpy: numpy $(version numpy) with scipy $(version scipy) : installing scipy $SCIPY_FALLBACK"
for attempt in 1 2 3 4 5; do
	uv pip install --reinstall --no-deps --no-cache "scipy==$SCIPY_FALLBACK" && break
	[ "$attempt" = 5 ] && { echo "fix-numpy: reinstall failed, leaving the image as it was"; exit 0; }
	sleep $((attempt * 10))
done
if preload_ok; then echo "fix-numpy: ok after reinstall"; else echo "fix-numpy: preload still fails (upstream issue, memory features affected)"; fi
exit 0
