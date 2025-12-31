# -----------------------------
# Base image
# -----------------------------
FROM node:20-bullseye

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# -----------------------------
# System dependencies
# -----------------------------
RUN apt-get update && apt-get install -y \
    python3 \
    python3-venv \
    python3-dev \
    curl \
    jq \
    clustalo \
    mafft \
    ncbi-blast+ \
    wget \
    perl \
    unzip \
    libssl1.1 \
    libqt5svg5-dev \
    python3-pyqt5 \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Copy backend code
# -----------------------------
COPY . .

# -----------------------------
# Install edirect (NCBI)
# -----------------------------
RUN wget https://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/edirect.tar.gz && \
    tar -xzf edirect.tar.gz && \
    rm edirect.tar.gz

# Make edirect tools available
ENV PATH="/app/edirect:${PATH}"

# -----------------------------
# Install FastTree
# -----------------------------
RUN wget -O /usr/local/bin/FastTree http://www.microbesonline.org/fasttree/FastTree && \
    chmod +x /usr/local/bin/FastTree

# -----------------------------
# Make scripts executable
# -----------------------------
RUN chmod +x scripts/*.sh || true

# -----------------------------
# Python virtual environment
# -----------------------------
RUN python3 -m venv venv && \
    ./venv/bin/pip install --upgrade pip && \
    ./venv/bin/pip install ete3==3.1.2 PyQt5 six numpy

# -----------------------------
# Node dependencies
# -----------------------------
RUN npm install

# -----------------------------
# Create required folders
# -----------------------------
RUN mkdir -p outputs uploads

# -----------------------------
# Expose backend port
# -----------------------------
EXPOSE 3000

# -----------------------------
# Run server
# -----------------------------
CMD ["node", "server.js"]
