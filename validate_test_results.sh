#!/bin/bash

# Script to validate test pipeline results
set -e

echo "Validating pipeline test results..."

# Check for expected output files
expected_files=(
    "results/fastqc/sample1_fastqc.html"
    "results/fastqc/sample2_fastqc.html"
    "results/multiqc/multiqc_report.html"
    "results/trimmed/sample1_trimmed_1.fastq.gz"
    "results/trimmed/sample2_trimmed_1.fastq.gz"
    "results/host_removed/sample1_host_removed_1.fastq.gz"
    "results/host_removed/sample2_host_removed_1.fastq.gz"
    "results/kraken2/sample1_kraken2.report"
    "results/kraken2/sample2_kraken2.report"
    "results/metaphlan/sample1_profile.txt"
    "results/metaphlan/sample2_profile.txt"
    "results/humann/sample1_genefamilies.tsv"
    "results/humann/sample2_genefamilies.tsv"
)

missing_files=0
for file in "${expected_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Missing file: $file"
        missing_files=$((missing_files + 1))
    fi
done

# Check file contents
check_file_content() {
    local file=$1
    local min_size=$2
    if [ -f "$file" ]; then
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file")
        if [ "$size" -lt "$min_size" ]; then
            echo "Warning: $file is smaller than expected ($size bytes)"
            return 1
        fi
    fi
    return 0
}

content_errors=0
check_file_content "results/kraken2/sample1_kraken2.report" 1000 || content_errors=$((content_errors + 1))
check_file_content "results/metaphlan/sample1_profile.txt" 1000 || content_errors=$((content_errors + 1))
check_file_content "results/humann/sample1_genefamilies.tsv" 1000 || content_errors=$((content_errors + 1))

# Final validation report
echo "Validation complete!"
echo "Missing files: $missing_files"
echo "Content warnings: $content_errors"

if [ $missing_files -eq 0 ] && [ $content_errors -eq 0 ]; then
    echo "All tests passed successfully!"
    exit 0
else
    echo "Some tests failed. Please check the validation report above."
    exit 1
fi