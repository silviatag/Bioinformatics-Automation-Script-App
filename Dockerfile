# Use official Node 20 image
FROM node:20-bullseye

# Set working directory
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive

# Copy system requirements
COPY requirements.txt .

# Install system packages + dependencies for Python, ETE3, and Qt rendering
RUN apt-get update && \
    xargs -a requirements.txt apt-get install -y \
        python3 \
        python3-venv \
        python3-dev \
        wget \
        curl \
        libqt5svg5-dev \
        python3-pyqt5 \
        libglib2.0-0 \
        libsm6 \
        libxrender1 \
        libxext6 \
    && rm -rf /var/lib/apt/lists/*


# Install FastTree
RUN wget -O /usr/local/bin/FastTree http://www.microbesonline.org/fasttree/FastTree && \
    chmod +x /usr/local/bin/FastTree

# Copy backend code
COPY . .

# Make scripts executable
RUN chmod +x scripts/*.sh

# Create Python virtual environment & install Python packages
RUN python3 -m venv venv && \
    ./venv/bin/pip install --upgrade pip && \
    ./venv/bin/pip install ete3==3.1.2 PyQt5 six numpy

# Install Node.js dependencies if package.json exists
RUN npm install 

# Create outputs folder
RUN mkdir -p outputs uploads

# Expose backend port
EXPOSE 3000

# Run server
CMD ["node", "server.js"]
