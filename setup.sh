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

echo "Setup completed successfully!"