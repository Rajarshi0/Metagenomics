#!/bin/bash
# ==============================================================================
#
#                         Database Download Script
#
# Description:
#   This script downloads the necessary databases for the metagenomics pipeline.
#   It is designed to be run INSIDE the Docker container.
#
# WARNING:
#   Database downloads can be very large and may take a long time to complete.
#   Ensure you have sufficient disk space and a stable internet connection.
#
# Usage:
#   (Inside the Docker container)
#   bash download.sh
#
# ==============================================================================

# --- Configuration ---
# Directory where all databases will be stored.
DB_DIR="databases"
GENOME_DIR="${DB_DIR}/human_genome"
KRAKEN_DIR="${DB_DIR}/kraken2_db"
THREADS=$(nproc)

# List of all URLs to check before starting
URLS_TO_CHECK=(
    "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/009/914/755/GCA_009914755.4_T2T-CHM13v2.0/GCA_009914755.4_T2T-CHM13v2.0_genomic.fna.gz"
)

# --- Helper Function ---
pre_flight_check() {
    echo "--- Performing Pre-Flight URL Check ---"
    local broken_links=()
    for url in "${URLS_TO_CHECK[@]}"; do
        echo "--> Checking link: ${url}"
        wget --spider -q "$url"
        if [ $? -ne 0 ]; then
            broken_links+=("$url")
        fi
    done

    if [ ${#broken_links[@]} -ne 0 ]; then
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "ERROR: The following download links are broken or inaccessible:"
        for link in "${broken_links[@]}"; do
            echo "  - ${link}"
        done
        echo "Please find alternative links and update this script before running again."
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        exit 1
    else
        echo "--> All links are valid. Proceeding with downloads."
        echo "----------------------------------------"
    fi
}

# --- Script Start ---
echo "Starting database download and setup..."
mkdir -p "${DB_DIR}"

# Run the pre-flight check on all URLs
pre_flight_check

# 1. Download Human Reference Genome (for host removal)
# ==============================================================================
echo "[Step 1/3] Downloading Human Reference Genome (T2T)..."
mkdir -p "${GENOME_DIR}"
GENOME_URL=${URLS_TO_CHECK[0]}
GENOME_DESTINATION="${GENOME_DIR}/human_T2T.fna.gz"

if [ -f "${GENOME_DESTINATION}" ]; then
    echo "Human genome already found. Skipping download."
else
    wget -O "${GENOME_DESTINATION}" "${GENOME_URL}"
    echo "Human genome downloaded."
fi

echo "[Step 2/3] Building Bowtie2 index for the human genome..."
echo "This is a computationally intensive step and may take a while."
if [ -f "${GENOME_DIR}/human_T2T.1.bt2" ]; then
    echo "Bowtie2 index already exists. Skipping build."
else
    # No need to activate conda, tools are in the PATH
    bowtie2-build --threads ${THREADS} "${GENOME_DESTINATION}" "${GENOME_DIR}/human_T2T"
    echo "Bowtie2 index built successfully."
fi

# 2. Download Kraken2 Database
# ==============================================================================
echo "[Step 3/3] Downloading and building Kraken2 standard database..."
echo "WARNING: This is a very large download and will take a long time."
mkdir -p "${KRAKEN_DIR}"

if [ -f "${KRAKEN_DIR}/hash.k2d" ]; then
    echo "Kraken2 database already seems to exist. Skipping download."
else
    # The kraken2-build command handles its own downloads.
    # The '--standard' flag downloads the standard collection of bacteria, archaea, and viral genomes.
    kraken2-build --standard --threads ${THREADS} --db "${KRAKEN_DIR}"
    echo "Kraken2 database downloaded and built."
fi

echo ""
echo "Database setup is complete!"
echo "All databases are located in the '${DB_DIR}' directory."
echo "You are now ready to run the main analysis pipeline: 'wholemetagenome.sh'"

