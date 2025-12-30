#!/bin/bash
set -e

echo "Multiple Sequence Alignment Script"

# -----------------------------
# MODE DETECTION
# -----------------------------
if [ "$#" -ge 4 ]; then
    MODE="API"
else
    MODE="USER"
fi

# -----------------------------
# USER MODE (interactive)
# -----------------------------
if [ "$MODE" = "USER" ]; then

    echo "Choose the interested Database:"
    echo "1) DNA"
    echo "2) Protein"
    read -p "Enter your choice (1 or 2): " db_choice

    echo "Choose MSA Tool:"
    echo "1) Clustal Omega"
    echo "2) MAFFT"
    read -p "Enter your choice (1 or 2): " tool_choice

    read -p "Enter your paths or Accession Numbers (space separated): " -a inputs
    read -p "Enter your Job_ID: " Job_ID

    if [ "$db_choice" -eq 1 ]; then
        DB_TYPE="DNA"
    elif [ "$db_choice" -eq 2 ]; then
        DB_TYPE="PROTEIN"
    else
        echo "Invalid database choice"
        exit 1
    fi

    if [ "$tool_choice" -eq 1 ]; then
        TOOL="clustal"
    elif [ "$tool_choice" -eq 2 ]; then
        TOOL="mafft"
    else
        echo "Invalid tool choice"
        exit 1
    fi
fi

# -----------------------------
# API MODE (non-interactive)
# -----------------------------
if [ "$MODE" = "API" ]; then
    DB_TYPE="$1"
    TOOL="$2"
    Job_ID="$3"
    shift 3
    inputs=("$@")
fi

# -----------------------------
# VALIDATION (shared)
# -----------------------------
if [ "${#inputs[@]}" -lt 2 ]; then
    echo "Error: At least two sequences are required"
    exit 1
fi

# -----------------------------
# OUTPUT DIRECTORY
# -----------------------------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTDIR="$PROJECT_ROOT/outputs/$Job_ID"
mkdir -p "$OUTDIR"

# -----------------------------
# FETCH SEQUENCES
# -----------------------------
resolved_fasta=()

for item in "${inputs[@]}"; do
    if [ -f "$item" ]; then
        cp "$item" "$OUTDIR/"  # copy local files to output dir
        resolved_fasta+=("$OUTDIR/$(basename "$item")")
        continue
    fi

    out_fasta="$OUTDIR/${item}.fasta"

    if [ "$DB_TYPE" = "DNA" ]; then
        efetch -db nucleotide -id "$item" -format fasta > "$out_fasta"
    elif [ "$DB_TYPE" = "PROTEIN" ]; then
        efetch -db protein -id "$item" -format fasta > "$out_fasta"
    else
        echo "Invalid DB_TYPE"
        exit 1
    fi

    resolved_fasta+=("$out_fasta")
done

# -----------------------------
# COMBINE FASTA
# -----------------------------
combined_fasta="$OUTDIR/combined_input_$Job_ID.fasta"
> "$combined_fasta"

for f in "${resolved_fasta[@]}"; do
    cat "$f" >> "$combined_fasta"
    echo >> "$combined_fasta"
done

# -----------------------------
# RUN MSA
# -----------------------------
MSA_OUTPUT="$OUTDIR/msa_result.fasta"

if [ "$TOOL" = "clustal" ]; then
    clustalo -i "$combined_fasta" -o "$MSA_OUTPUT" --force
elif [ "$TOOL" = "mafft" ]; then
    mafft "$combined_fasta" > "$MSA_OUTPUT"
else
    echo "Invalid TOOL"
    exit 1
fi

echo "MSA completed"
echo "Fetched sequences saved in: $OUTDIR"
echo "Combined MSA saved at: $MSA_OUTPUT"
