#!/bin/bash

# Setup script for metagenomics pipeline
set -e

echo "Setting up metagenomics pipeline dependencies..."

# Create conda environment
conda create -n metagenomics python=3.9 -y

# Activate environment
source activate metagenomics

# Install basic tools
conda install -c bioconda \
    snakemake \
    fastqc \
    multiqc \
    trimmomatic \
    bowtie2 \
    kraken2 \
    metaphlan \
    humann \
    -y

# Create directory structure
mkdir -p {data,results,logs,resources,config}

# Download Kraken2 database (MiniKraken2_v1_8GB for testing)
wget https://genome-idx.s3.amazonaws.com/kraken/k2_standard_08gb_20221209.tar.gz -P resources/
tar -xzf resources/k2_standard_08gb_20221209.tar.gz -C resources/

# Download MetaPhlAn database
metaphlan --install --bowtie2db resources/metaphlan_databases/

# Download HUMANn database (ChocoPhlAn)
humann_databases --download chocophlan full resources/humann_databases/
humann_databases --download uniref uniref90_diamond resources/humann_databases/

echo "Setup completed successfully!"