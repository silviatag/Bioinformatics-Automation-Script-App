#!/bin/bash
set -e

MSA="$1"
DATA_TYPE="$2"
JOB_ID="$3"

# Validation
if [ -z "$MSA" ] || [ -z "$DATA_TYPE" ] || [ -z "$JOB_ID" ]; then
  echo "Usage: $0 <MSA_FILE> <DNA|PROTEIN> <JOB_ID>"
  exit 1
fi

if [ ! -f "$MSA" ]; then
  echo "Error: MSA file not found at $MSA"
  exit 1
fi

if ! command -v FastTree &> /dev/null; then
  echo "Error: FastTree not installed"
  exit 1
fi

# Output paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTDIR="$PROJECT_ROOT/outputs/$JOB_ID"
TREE="$OUTDIR/tree.newick"
IMG="$OUTDIR/tree.png"
mkdir -p "$OUTDIR"

echo "[TREE] MSA: $MSA"
echo "[TREE] Type: $DATA_TYPE"
echo "[TREE] Job ID: $JOB_ID"

# Run FastTree
if [ "$DATA_TYPE" = "PROTEIN" ]; then
  FastTree -protein "$MSA" > "$TREE"
else
  FastTree "$MSA" > "$TREE"
fi

echo "[TREE] Newick created at $TREE"

# Render tree image
if [ -f "venv/bin/python" ]; then
  ./venv/bin/python scripts/render_tree.py "$TREE" "$IMG"
  echo "[TREE] Image created at $IMG"
else
  echo "[TREE] Python venv missing, cannot render image"
fi

# Output paths for server.js
echo "RESULT_TREE=$TREE"
echo "RESULT_IMAGE=$IMG"
