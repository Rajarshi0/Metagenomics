# Automated Metagenomics Pipeline

[Previous README content...]

## Testing the Pipeline

This pipeline comes with test data and a script to run a test analysis:

1. Download the test data:
```bash
chmod +x download_test_data.sh
./download_test_data.sh
```

2. Run the test pipeline:
```bash
./run_test_pipeline.sh
```

The test run uses:
- Two small metagenomic samples from the Human Microbiome Project
- Reduced database sizes for quick testing
- 4 CPU cores instead of 8 for wider compatibility

Expected test runtime: ~30-60 minutes depending on your system.

### Test Output Validation

After the test run completes, you should see:
1. FastQC reports for both samples
2. Kraken2 taxonomic classifications
3. MetaPhlAn profiles
4. HUMAnN functional annotations

The test results will be in the `results` directory with the same structure as a full run.

[Rest of README content...]