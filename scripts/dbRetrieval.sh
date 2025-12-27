# ===========================================
#   Bioinformatics Automation: Data Fetch
#   Supports:
#   - Interactive (user mode)
#   - Non-interactive (API/backend mode)
# ===========================================

set -e

# ------------------------------
# MODE DETECTION
# ------------------------------
if [ "$#" -eq 3 ]; then
    # API / backend mode
    CHOICE="$1"
    KEYWORD="$2"
    JOB_ID="$3"
    # outfile="$3"
else
    # Interactive user mode
    echo "==========================================="
    echo "   Bioinformatics Automation: Data Fetch   "
    echo "==========================================="
    echo
    echo "Choose a database to search:"
    echo "1) NCBI Nucleotide (nuccore)"
    echo "2) NCBI Protein (protein)"
    echo "3) UniProt KB"
    echo
    read -p "Enter CHOICE (1/2/3): " CHOICE
    read -p "Enter search KEYWORD: " KEYWORD
    read -p "Enter output file name (e.g., result.fasta): " outfile
fi

# echo
# echo "Fetching sequences..."
# echo

# Output paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTDIR="$PROJECT_ROOT/outputs/$JOB_ID"
OUTFILE="$OUTDIR/$KEYWORD.fasta"
mkdir -p "$OUTDIR"
# ------------------------------
# NCBI Nucleotide
# ------------------------------
if [ "$CHOICE" = "1" ]; then
    # echo "Searching NCBI Nucleotide (nuccore)..."

    esearch -db nuccore -query "$KEYWORD" \
        | efetch -format fasta > "$OUTFILE"

# ------------------------------
# NCBI Protein
# ------------------------------
elif [ "$CHOICE" = "2" ]; then
    # echo "Searching NCBI Protein (protein)..."

    esearch -db protein -query "$KEYWORD" \
        | efetch -format fasta > "$OUTFILE"
# ------------------------------
# UniProt KB
# ------------------------------
elif [ "$CHOICE" = "3" ]; then
    # echo "Searching UniProt KB..."

    curl -fsSL \
        "https://rest.uniprot.org/uniprotkb/search?query=${KEYWORD}&format=fasta" \
        -o "$OUTFILE"

else
    # echo "Invalid CHOICE. Use 1, 2, or 3."
    exit 1
fi

# ------------------------------
# VALIDATION
# ------------------------------
if [ ! -s "$OUTFILE" ]; then
    # echo "No results found for: $KEYWORD"
    rm -f "$OUTFILE"
    exit 2
fi

# echo "Results saved to: $OUTFILE"
# echo "Retrieval complete!"
cat "$OUTFILE"