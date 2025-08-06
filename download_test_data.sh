#!/bin/bash

# Script to download test data for metagenomics pipeline
set -e

echo "Downloading test datasets..."

# Create data directory if it doesn't exist
mkdir -p data/test_samples

# Download small test dataset from Human Microbiome Project (HMP)
# These are gut microbiome samples, trimmed to be smaller for testing purposes

# Download first test sample
wget -O data/test_samples/sample1_1.fastq.gz \
    "https://raw.githubusercontent.com/LangilleLab/microbiome_helper/master/data/hmp_data_subset/sample1_R1.fastq.gz"
wget -O data/test_samples/sample1_2.fastq.gz \
    "https://raw.githubusercontent.com/LangilleLab/microbiome_helper/master/data/hmp_data_subset/sample1_R2.fastq.gz"

# Download second test sample
wget -O data/test_samples/sample2_1.fastq.gz \
    "https://raw.githubusercontent.com/LangilleLab/microbiome_helper/master/data/hmp_data_subset/sample2_R1.fastq.gz"
wget -O data/test_samples/sample2_2.fastq.gz \
    "https://raw.githubusercontent.com/LangilleLab/microbiome_helper/master/data/hmp_data_subset/sample2_R2.fastq.gz"

# Create test configuration file
cat > config/test_config.yaml << EOL
# Test sample information
samples:
    - "sample1"
    - "sample2"

# Databases (using smaller test databases for quick testing)
kraken2_db: "resources/kraken2_db"
metaphlan_db: "resources/metaphlan_databases"
chocophlan_db: "resources/humann_databases/chocophlan"
uniref_db: "resources/humann_databases/uniref"

# Reference genomes
host_genome: "resources/host_genome/genome"
adapter_file: "resources/adapters/TruSeq3-PE.fa"

# Parameters for test run
threads: 4
EOL

# Create a test script
cat > run_test_pipeline.sh << EOL
#!/bin/bash

# Script to run the pipeline with test data
set -e

echo "Running metagenomics pipeline with test data..."

# Activate conda environment
source activate metagenomics

# Run snakemake with test configuration
snakemake --configfile config/test_config.yaml \
    --use-conda \
    --cores 4 \
    --printshellcmds \
    --rerun-incomplete \
    2>&1 | tee pipeline_test.log

echo "Test run completed! Check pipeline_test.log for details."
EOL

# Make the test script executable
chmod +x run_test_pipeline.sh

echo "Test data downloaded successfully!"
echo "You can now run the test pipeline using: ./run_test_pipeline.sh"