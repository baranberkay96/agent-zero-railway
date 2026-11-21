#!/bin/bash
# Keep the numeric stack in a fresh directory. Deleting/reinstalling packages
# in the base image's site-packages produced clean build imports but Railway's
# runtime still contained old SciPy extension files alongside the new release.
# A separate import root avoids that mixed tree without disabling embeddings.
set -Eeuo pipefail

readonly PYTHON=/opt/venv-a0/bin/python
readonly NUMERIC_ROOT=/opt/railway-numeric

for attempt in 1 2 3 4 5; do
  if uv pip install --python "$PYTHON" --target "$NUMERIC_ROOT" \
    --no-deps --no-cache --only-binary=:all: numpy==1.26.4 scipy==1.14.1; then
    break
  fi
  if [ "$attempt" = 5 ]; then
    echo 'fix-numpy: numeric dependency installation failed' >&2
    exit 1
  fi
  sleep $((attempt * 10))
done

# Scope the import path to the app's CPython 3.12 virtualenv. The image also
# contains a separate Python 3.13 environment; a global PYTHONPATH would send
# that interpreter to incompatible CPython 3.12 extension modules.
"$PYTHON" - <<'PY'
from pathlib import Path
import sysconfig
site = Path(sysconfig.get_paths()['purelib'])
(site / 'railway-numeric.pth').write_text(
    "import sys; sys.path.insert(0, '/opt/railway-numeric')\n"
)
PY

# Exercise the actual local embedding model, not only preload.py: before the
# first startup migration, upstream preload can skip its uninitialized preset.
"$PYTHON" - <<'PY'
import numpy as np
import scipy.special
import scipy.sparse.linalg
import scipy
from sentence_transformers import SentenceTransformer
assert np.__file__.startswith('/opt/railway-numeric/'), np.__file__
assert scipy.__file__.startswith('/opt/railway-numeric/'), scipy.__file__
model = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')
vectors = model.encode(['Railway build-time embedding verification'])
assert vectors.shape == (1, 384), vectors.shape
assert np.isfinite(vectors).all()
print('fix-numpy: clean numeric imports and 384-dimensional embedding verified')
PY
