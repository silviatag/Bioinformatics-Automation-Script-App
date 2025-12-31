#!/bin/bash
set -e


TOOL="$1"
SEQ1="$2"
SEQ2="$3"  
JOB_ID="$4"
# ---------------- Validation ----------------
if [ ! -f "$SEQ1" ]; then
  echo "Error: First FASTA file not found at $SEQ1"
  exit 1
fi

if [ ! -f "$SEQ2" ]; then
  echo "Error: Second FASTA file not found at $SEQ2"
  exit 1
fi

if [ -z "$TOOL" ]; then
  echo "Error: Please specify alignment tool as 4th argument ('blast' or 'needle')"
  exit 1
fi

# ---------------- Paths ----------------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTDIR="$PROJECT_ROOT/outputs/$JOB_ID"

mkdir -p "$OUTDIR"

# ---------------- Run selected tool ----------------
if [ "$TOOL" == "blast" ]; then
  if ! command -v blastn &> /dev/null; then
    echo "Error: BLAST+ not installed"
    exit 1
  fi

  HUMAN_ALIGNMENT="$OUTDIR/blast_alignment.txt"
  ALIGNMENT_TABLE="$OUTDIR/blast_table.txt"

#   echo "Running BLAST alignment..."
  blastn -query "$SEQ1" -subject "$SEQ2" -outfmt 0 -out "$HUMAN_ALIGNMENT"
  blastn -query "$SEQ1" -subject "$SEQ2" -outfmt 7 -out "$ALIGNMENT_TABLE"

  # Print human-readable alignment
  cat "$HUMAN_ALIGNMENT"

elif [ "$TOOL" == "needle" ]; then
  if ! command -v needle &> /dev/null; then
    echo "Error: Needle (EMBOSS) not installed"
    exit 1
  fi

  HUMAN_ALIGNMENT="$OUTDIR/needle_alignment.txt"

#   echo "Running Needle alignment..."
  needle -asequence "$SEQ1" -bsequence "$SEQ2" -gapopen 10 -gapextend 0.5 -outfile "$HUMAN_ALIGNMENT"

#   echo "Done! Alignment saved in $HUMAN_ALIGNMENT"
  cat "$HUMAN_ALIGNMENT"

else
  echo "Error: Invalid tool '$TOOL'. Use 'blast' or 'needle'."
  exit 1
fi
