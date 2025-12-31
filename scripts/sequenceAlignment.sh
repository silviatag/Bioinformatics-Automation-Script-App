#!/bin/bash
set -e

SEQ1="$1"
SEQ2="$2"
JOB_ID="$3"

# ---------------- Validation ----------------
if [ ! -f "$SEQ1" ]; then
  echo "Error: First FASTA file not found at $SEQ1"
  exit 1
fi

if [ ! -f "$SEQ2" ]; then
  echo "Error: Second FASTA file not found at $SEQ2"
  exit 1
fi

if ! command -v blastn &> /dev/null; then
  echo "Error: BLAST+ not installed"
  exit 1
fi

# ---------------- Paths ----------------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTDIR="$PROJECT_ROOT/outputs/$JOB_ID"

HUMAN_ALIGNMENT="$OUTDIR/blast_alignment.txt"
ALIGNMENT_TABLE="$OUTDIR/blast_table.txt"

mkdir -p "$OUTDIR"

# ---------------- Run BLAST ----------------
blastn \
  -query "$SEQ1" \
  -subject "$SEQ2" \
  -outfmt 0 \
  -out "$HUMAN_ALIGNMENT"

blastn \
  -query "$SEQ1" \
  -subject "$SEQ2" \
  -outfmt 7 \
  -out "$ALIGNMENT_TABLE"


# Print ONLY human-readable alignment (for BE response)
cat "$HUMAN_ALIGNMENT"
