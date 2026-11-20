#!/bin/bash
# Build-time repair (Railway template): the v2.16 image's Python environment
# holds files of two numpy releases (upstream installs its requirements twice),
# so `import scipy.special` fails and Agent Zero logs "Error in preload: All
# ufuncs must have type numpy.ufunc", which breaks memory/embedding features.
# Reinstall the numpy 1.x release that the image's dist-info declares, cleanly.
set -euo pipefail
source /opt/venv-a0/bin/activate
if python -c "import scipy.special" 2>/dev/null; then
	echo "fix-numpy: scipy.special imports fine, nothing to do"
	exit 0
fi
site=$(python -c "import sysconfig; print(sysconfig.get_paths()['purelib'])")
ver=$(find "$site" -maxdepth 1 -type d -name 'numpy-1.*.dist-info' -printf '%f\n' | sed -E 's/^numpy-(.*)\.dist-info$/\1/' | sort -V | tail -1)
if [ -z "$ver" ]; then
	ver=$(find "$site" -maxdepth 1 -type d -name 'numpy-*.dist-info' -printf '%f\n' | sed -E 's/^numpy-(.*)\.dist-info$/\1/' | sort -V | head -1)
fi
echo "fix-numpy: reinstalling numpy $ver (found: $(find "$site" -maxdepth 1 -name 'numpy-*.dist-info' -printf '%f ' ))"
rm -rf "$site/numpy" "$site"/numpy-*.dist-info "$site/numpy.libs"
for attempt in 1 2 3 4 5; do
	uv pip install --no-deps --no-cache "numpy==$ver" && break
	[ "$attempt" = 5 ] && exit 1
	sleep $((attempt * 10))
done
python -c "import numpy, scipy.special, faiss; print('fix-numpy: ok, numpy', numpy.__version__)"
