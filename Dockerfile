# ==============================================================================
# Dockerfile for a Comprehensive Metagenomics Pipeline
#
# Description:
#   This Dockerfile creates a single, self-contained environment with all
#   necessary tools for state-of-the-art metagenomic analysis strategies:
#   1. Read-Based (Kraken2/Bracken)
#   2. Read-Based (MetaPhlAn/HUMAnN)
#   3. Assembly-Based (MEGAHIT/MetaBat2/GTDB-Tk/eggNOG-mapper)
#
# Fixed issues:
#   - Proper multi-stage build
#   - Correct dependency management
#   - Fixed Python package installation
#   - Proper tool compilation and installation
#   - Added missing dependencies
#   - Fixed file paths and permissions
# ==============================================================================

# --- STAGE 1: The Builder ---
FROM ubuntu:20.04 AS builder

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install dependencies including GSL for CONCOCT
RUN apt-get update && apt-get install -y \
    build-essential \
    g++ \
    make \
    wget \
    unzip \
    git \
    zlib1g-dev \
    python3-pip \
    python3-dev \
    ca-certificates \
    rsync \
    hmmer \
    prodigal \
    cython3 \
    libhdf5-dev \
    pkg-config \
    cmake \
    libboost-all-dev \
    libgsl-dev \
    libatlas-base-dev \
    libblas-dev \
    liblapack-dev \
    gfortran \
    tzdata \
    --no-install-recommends && \
    ln -fs /usr/share/zoneinfo/Asia/Kolkata /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip3 install --no-cache-dir numpy scipy cython pandas h5py scikit-learn matplotlib biopython


# Set up the installation directory
ENV INSTALL_DIR=/opt/tools
ENV PATH="${INSTALL_DIR}/bin:${PATH}"
RUN mkdir -p ${INSTALL_DIR}/bin ${INSTALL_DIR}/lib ${INSTALL_DIR}/include

WORKDIR ${INSTALL_DIR}

# Update pip and install build tools
RUN python3 -m pip install --upgrade pip setuptools wheel

# --- Install Core Python Packages First ---
RUN pip3 install --no-cache-dir \
    numpy==1.21.6 \
    scipy==1.7.3 \
    pandas==1.3.5 \
    matplotlib==3.5.3 \
    seaborn==0.11.2 \
    biopython==1.79 \
    scikit-learn==1.0.2 \
    h5py==3.7.0 \
    networkx==2.6.3

# --- Install Bioinformatics Python Tools ---
RUN pip3 install --no-cache-dir \
    multiqc==1.13 \
    checkm-genome==1.2.2

# Install MetaPhlAn and HUMAnN (with specific versions to avoid conflicts)
RUN pip3 install --no-cache-dir \
    metaphlan==4.0.6 \
    humann==3.6.1

# Install GTDB-Tk dependencies
RUN pip3 install --no-cache-dir \
    gtdbtk==2.3.2 \
    dendropy==4.5.2 \
    tqdm==4.64.1

# Install eggNOG-mapper
RUN pip3 install --no-cache-dir \
    eggnog-mapper==2.1.12


RUN apt-get update && apt-get install -y \
    libncurses-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    autoconf \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# --- Install Samtools (needed by many tools) ---
RUN wget https://github.com/samtools/samtools/releases/download/1.17/samtools-1.17.tar.bz2 && \
    tar -xjf samtools-1.17.tar.bz2 && \
    cd samtools-1.17 && \
    ./configure --prefix=${INSTALL_DIR} && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf samtools-1.17*

# --- Install BWA (alignment tool) ---
RUN git clone https://github.com/lh3/bwa.git && \
    cd bwa && \
    make -j$(nproc) && \
    cp bwa ${INSTALL_DIR}/bin/ && \
    cd .. && \
    rm -rf bwa

# --- Install fastp ---
RUN wget http://opengene.org/fastp/fastp && \
    chmod +x fastp && \
    mv fastp ${INSTALL_DIR}/bin/

# --- Install Bowtie2 ---
RUN wget https://github.com/BenLangmead/bowtie2/releases/download/v2.5.1/bowtie2-2.5.1-linux-x86_64.zip && \
    unzip bowtie2-2.5.1-linux-x86_64.zip && \
    cp bowtie2-2.5.1-linux-x86_64/bowtie2* ${INSTALL_DIR}/bin/ && \
    rm -rf bowtie2-2.5.1*

# --- Install Kraken2 ---
RUN wget https://github.com/DerrickWood/kraken2/archive/refs/tags/v2.1.3.tar.gz && \
    tar -xzf v2.1.3.tar.gz && \
    cd kraken2-2.1.3 && \
    ./install_kraken2.sh ${INSTALL_DIR}/bin && \
    cd .. && \
    rm -rf kraken2-2.1.3 v2.1.3.tar.gz

# --- Install Bracken ---
RUN wget https://github.com/jenniferlu717/Bracken/archive/refs/tags/v2.9.tar.gz && \
    tar -xzf v2.9.tar.gz && \
    cd Bracken-2.9 && \
    bash install_bracken.sh && \
    cp bracken bracken-build ${INSTALL_DIR}/bin/ && \
    cp -r src ${INSTALL_DIR}/lib/bracken_src && \
    cd .. && \
    rm -rf Bracken-2.9 v2.9.tar.gz

# --- Install MEGAHIT ---
RUN wget https://github.com/voutcn/megahit/releases/download/v1.2.9/MEGAHIT-1.2.9-Linux-x86_64-static.tar.gz && \
    tar -xzf MEGAHIT-1.2.9-Linux-x86_64-static.tar.gz && \
    cp MEGAHIT-1.2.9-Linux-x86_64-static/bin/* ${INSTALL_DIR}/bin/ && \
    rm -rf MEGAHIT-1.2.9*

# --- Install SPAdes ---
RUN wget https://github.com/ablab/spades/releases/download/v3.15.5/SPAdes-3.15.5-Linux.tar.gz && \
    tar -xzf SPAdes-3.15.5-Linux.tar.gz && \
    cp SPAdes-3.15.5-Linux/bin/* ${INSTALL_DIR}/bin/ && \
    rm -rf SPAdes-3.15.5*

# --- Install MetaBat2 ---
RUN git clone https://bitbucket.org/berkeleylab/metabat.git && \
    cd metabat && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} .. && \
    make -j$(nproc) && \
    make install && \
    cd ../.. && \
    rm -rf metabat

# --- Install MaxBin2 ---
# Install MaxBin2
RUN wget -O MaxBin-2.2.7.tar.gz https://sourceforge.net/projects/maxbin2/files/latest/download && \
    tar -xzf MaxBin-2.2.7.tar.gz && \
    cd MaxBin-2.2.7 && \
    cd src && \
    make && \
    cd .. && \
    ./autobuild_auxiliary && \
    mkdir -p ${INSTALL_DIR}/bin && \
    cp run_MaxBin.pl ${INSTALL_DIR}/bin/ && \
    mkdir -p ${INSTALL_DIR}/lib/MaxBin && \
    cp -r auxiliary src ${INSTALL_DIR}/lib/MaxBin/ && \
    cd .. && \
    rm -rf MaxBin-2.2.7* MaxBin-2.2.7.tar.gz



# --- Install CONCOCT ---
RUN git clone https://github.com/BinPro/CONCOCT.git && \
    cd CONCOCT && \
    python3 setup.py install && \
    cd .. && \
    rm -rf CONCOCT

# --- Install DAS Tool ---
RUN git clone https://github.com/cmks/DAS_Tool.git && \
    cd DAS_Tool && \
    unzip db.zip -d db && \
    chmod +x DAS_Tool && \
    mv DAS_Tool /usr/local/bin/ && \
    mv db /opt/das_tool_db && \
    cd .. && \
    rm -rf DAS_Tool

# --- Install Prokka ---
RUN git clone https://github.com/tseemann/prokka.git && \
    cd prokka && \
    cp bin/* ${INSTALL_DIR}/bin/ && \
    mkdir -p ${INSTALL_DIR}/lib/prokka && \
    cp -r db binaries ${INSTALL_DIR}/lib/prokka/ && \
    cd .. && \
    rm -rf prokka

# --- Install DIAMOND ---
RUN wget http://github.com/bbuchfink/diamond/releases/download/v2.1.9/diamond-linux64.tar.gz && \
    tar -xzf diamond-linux64.tar.gz && \
    mv diamond ${INSTALL_DIR}/bin/ && \
    rm diamond-linux64.tar.gz

# --- Install QUAST ---
RUN git clone https://github.com/ablab/quast.git && \
    cd quast && \
    python3 setup.py install && \
    cd .. && \
    rm -rf quast

# --- Install BUSCO ---
# Install core dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    python3 python3-pip python3-dev python3-venv \
    git wget unzip curl \
    hmmer \
    ncbi-blast+ \
    libsqlite3-dev \
    libx11-dev \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Optional: install Metaeuk and SEPP if needed by lineage datasets
# Metaeuk
# Install MetaEuk AVX2 static binary
RUN wget https://mmseqs.com/metaeuk/metaeuk-linux-avx2.tar.gz && \
    tar xzvf metaeuk-linux-avx2.tar.gz && \
    mv metaeuk /opt/metaeuk && \
    ln -s /opt/metaeuk/bin/* /usr/local/bin/ && \
    rm metaeuk-linux-avx2.tar.gz



# SEPP (small installation for BUSCO)
# Install required system packages
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    build-essential \
    wget \
    unzip

# Install Python packages needed by SEPP
RUN pip3 install numpy dendropy

# Clone SEPP
# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    build-essential \
    wget \
    unzip

# Set up SEPP working directory
WORKDIR /opt

# Clone SEPP
RUN git clone https://github.com/smirarab/sepp.git

# Enter SEPP directory
WORKDIR /opt/sepp

# Install SEPP Python dependencies
RUN pip3 install numpy dendropy

# Run SEPP config (write config files in current dir, not /root)
RUN python3 setup.py config -c

# Install SEPP locally
RUN python3 setup.py install --user

# Add local bin to PATH so SEPP is available
ENV PATH="/root/.local/bin:$PATH"




# Install Augustus manually

# Install missing dependencies for Augustus
RUN apt-get update && apt-get install -y \
    libboost-all-dev \
    zlib1g-dev \
    libeigen3-dev \
    libgsl-dev \
    libsqlite3-dev \
    libxml2-dev \
    liblpsolve55-dev \
    pkg-config \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# Clone and compile AUGUSTUS without MySQL++ or bam2hints
RUN git clone --depth 1 https://github.com/Gaius-Augustus/Augustus.git /opt/augustus && \
    cd /opt/augustus && \
    sed -i 's/-DM_MYSQL//g' src/Makefile && \
    sed -i 's/-lmysqlpp//g' src/Makefile && \
    sed -i 's/-lmysqlclient//g' src/Makefile && \
    sed -i '/load2db/d' src/Makefile && \
    sed -i '/mysql_connection.cc/d' src/Makefile && \
    sed -i '/mysql_connection.o/d' src/Makefile && \
    make augustus && \
    make install


# Clone and install BUSCO from source
RUN git clone https://gitlab.com/ezlab/busco.git /opt/busco && \
    cd /opt/busco && \
    pip3 install .

# Optional: Add BUSCO to PATH
ENV PATH="/opt/busco/bin:$PATH"



RUN pip3 install --no-cache-dir \
    ete3 \
    matplotlib \
    seaborn \
    biopython \
    numpy \
    pyqt5

# Add Augustus config path
ENV AUGUSTUS_CONFIG_PATH=/usr/local/config

# Test BUSCO installation
RUN busco --help







# --- Install seqtk ---
RUN git clone https://github.com/lh3/seqtk.git && \
    cd seqtk && \
    make -j$(nproc) && \
    cp seqtk ${INSTALL_DIR}/bin/ && \
    cd .. && \
    rm -rf seqtk

# --- Install BBTools ---
RUN wget https://sourceforge.net/projects/bbmap/files/BBMap_39.01.tar.gz && \
    tar -xzf BBMap_39.01.tar.gz && \
    mkdir -p ${INSTALL_DIR}/lib/bbmap && \
    cp -r bbmap/* ${INSTALL_DIR}/lib/bbmap/ && \
    chmod +x ${INSTALL_DIR}/lib/bbmap/*.sh && \
    # Create symlinks for common tools
    ln -s ${INSTALL_DIR}/lib/bbmap/bbmap.sh ${INSTALL_DIR}/bin/bbmap.sh && \
    ln -s ${INSTALL_DIR}/lib/bbmap/bbduk.sh ${INSTALL_DIR}/bin/bbduk.sh && \
    rm -rf bbmap BBMap_39.01.tar.gz

# --- Install CoverM ---
RUN wget https://github.com/wwood/CoverM/releases/download/v0.6.1/coverm-x86_64-unknown-linux-musl-0.6.1.tar.gz && \
    tar -xzf coverm-x86_64-unknown-linux-musl-0.6.1.tar.gz && \
    chmod +x coverm-x86_64-unknown-linux-musl-0.6.1 && \
    mv coverm-x86_64-unknown-linux-musl-0.6.1 ${INSTALL_DIR}/bin/coverm && \
    rm coverm-x86_64-unknown-linux-musl-0.6.1.tar.gz

# --- Install Mash ---
RUN wget https://github.com/marbl/Mash/releases/download/v2.3/mash-Linux64-v2.3.tar && \
    tar -xf mash-Linux64-v2.3.tar && \
    cp mash-Linux64-v2.3/mash ${INSTALL_DIR}/bin/ && \
    rm -rf mash-Linux64-v2.3*

# --- Install Sourmash ---
RUN pip3 install sourmash
# --- Install FastQC ---
RUN wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip && \
    unzip fastqc_v0.11.9.zip && \
    chmod +x FastQC/fastqc && \
    cp FastQC/fastqc ${INSTALL_DIR}/bin/ && \
    mkdir -p ${INSTALL_DIR}/lib/fastqc && \
    cp -r FastQC/* ${INSTALL_DIR}/lib/fastqc/ && \
    rm -rf FastQC fastqc_v0.11.9.zip

# --- STAGE 2: The Final Image ---
FROM ubuntu:20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV INSTALL_DIR=/opt/tools
ENV PATH="${INSTALL_DIR}/bin:/usr/local/bin:${PATH}"

# Install only runtime dependencies
RUN apt-get update && \
    apt-get install -y \
    python3 \
    python3-pip \
    perl \
    default-jre \
    pigz \
    wget \
    curl \
    ca-certificates \
    rsync \
    hmmer \
    prodigal \
    libhdf5-103 \
    libhdf5-serial-dev \
    libboost-program-options1.71.0 \
    libboost-filesystem1.71.0 \
    libboost-system1.71.0 \
    libboost-graph1.71.0 \
    libboost-serialization1.71.0 \
    libboost-iostreams1.71.0 \
    zlib1g \
    libbz2-1.0 \
    liblzma5 \
    libncurses5 \
    libcurl4 \
    libssl1.1 \
    r-base-core \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p ${INSTALL_DIR}/bin ${INSTALL_DIR}/lib ${INSTALL_DIR}/databases /data


RUN python3 -c "import site; print(site.getsitepackages())"

# Copy the installed tools from the builder stage
COPY --from=builder ${INSTALL_DIR}/ ${INSTALL_DIR}/
#COPY --from=builder /usr/local/lib/python3.8/site-packages/ /usr/local/lib/python3.8/site-packages/
#COPY --from=builder /usr/local/lib/python3.10/site-packages/ /usr/local/lib/python3.10/site-packages/
#COPY --from=builder /usr/local/bin/ /usr/local/bin/

# Fix permissions
#RUN chmod -R +x ${INSTALL_DIR}/bin/*
RUN find ${INSTALL_DIR}/bin -type f -exec chmod +x {} \; || echo "No binaries to chmod"


# Create symbolic links for common tools that might be expected in standard locations
RUN ln -sf ${INSTALL_DIR}/bin/samtools /usr/local/bin/samtools && \
    ln -sf ${INSTALL_DIR}/bin/bowtie2 /usr/local/bin/bowtie2 && \
    ln -sf ${INSTALL_DIR}/bin/kraken2 /usr/local/bin/kraken2 && \
    ln -sf ${INSTALL_DIR}/bin/bracken /usr/local/bin/bracken

# Set environment variables for specific tools
ENV PROKKA_DBDIR="${INSTALL_DIR}/lib/prokka/db"
ENV BUSCO_CONFIG_FILE="${INSTALL_DIR}/lib/busco/config.ini"

# Create a setup script for databases
COPY <<EOF /usr/local/bin/setup_databases.sh
#!/bin/bash
set -euo pipefail

echo "Setting up metagenomics databases..."

# Create database directories
mkdir -p ${INSTALL_DIR}/databases/{kraken2,metaphlan,checkm,gtdb,busco,eggnog}

# Setup MetaPhlAn database
if [ ! -f "${INSTALL_DIR}/databases/metaphlan/mpa_vOct22_CHOCOPhlAnSGB_202212.pkl" ]; then
    echo "Setting up MetaPhlAn database..."
    metaphlan --install --bowtie2db ${INSTALL_DIR}/databases/metaphlan/
fi

# Setup BUSCO databases
echo "Setting up BUSCO databases..."
busco --download_path ${INSTALL_DIR}/databases/busco --download bacteria_odb10
busco --download_path ${INSTALL_DIR}/databases/busco --download archaea_odb10

# Setup CheckM database
if [ ! -d "${INSTALL_DIR}/databases/checkm/checkm_data" ]; then
    echo "Setting up CheckM database..."
    mkdir -p ${INSTALL_DIR}/databases/checkm/checkm_data
    cd ${INSTALL_DIR}/databases/checkm/checkm_data
    wget -c https://data.ace.uq.edu.au/public/CheckM_databases/checkm_data_2015_01_16.tar.gz
    tar -xzf checkm_data_2015_01_16.tar.gz
    rm checkm_data_2015_01_16.tar.gz
    checkm data setRoot \$(pwd)
fi

echo "Database setup complete!"
EOF

RUN chmod +x /usr/local/bin/setup_databases.sh

# Create a pipeline test script
COPY <<EOF /usr/local/bin/test_pipeline.sh
#!/bin/bash
set -euo pipefail

echo "Testing metagenomics pipeline tools..."

# Test basic tools
echo "Testing fastp..." && fastp --version
echo "Testing bowtie2..." && bowtie2 --version
echo "Testing samtools..." && samtools --version
echo "Testing kraken2..." && kraken2 --version
echo "Testing megahit..." && megahit --version
echo "Testing metabat2..." && metabat2 --help > /dev/null && echo "metabat2 OK"
echo "Testing diamond..." && diamond version
echo "Testing fastqc..." && fastqc --version
echo "Testing multiqc..." && multiqc --version

# Test Python packages
echo "Testing Python packages..."
python3 -c "import metaphlan; print('MetaPhlAn OK')"
python3 -c "import humann; print('HUMAnN OK')"
python3 -c "import checkm; print('CheckM OK')"

echo "All tests passed!"
EOF

RUN chmod +x /usr/local/bin/test_pipeline.sh

# Set a working directory for analysis
WORKDIR /data

# Set the entrypoint to bash
CMD ["/bin/bash"]

# Add labels for better image management
LABEL maintainer="Metagenomics Pipeline"
LABEL description="Comprehensive metagenomics analysis environment"
LABEL version="1.0"
