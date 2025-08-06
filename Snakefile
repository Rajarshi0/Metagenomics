configfile: "config/config.yaml"

# Define global variables
SAMPLES = config["samples"]
RESULTS = "results"
LOGS = "logs"

# Final target rule
rule all:
    input:
        expand(f"{RESULTS}/fastqc/{{sample}}_fastqc.html", sample=SAMPLES),
        f"{RESULTS}/multiqc/multiqc_report.html",
        expand(f"{RESULTS}/kraken2/{{sample}}_kraken2.report", sample=SAMPLES),
        expand(f"{RESULTS}/metaphlan/{{sample}}_profile.txt", sample=SAMPLES),
        expand(f"{RESULTS}/humann/{{sample}}_genefamilies.tsv", sample=SAMPLES),
        f"{RESULTS}/final_report.html"

# Quality control
rule fastqc:
    input:
        "data/raw/{sample}_1.fastq.gz"
    output:
        html=f"{RESULTS}/fastqc/{{sample}}_fastqc.html",
        zip=f"{RESULTS}/fastqc/{{sample}}_fastqc.zip"
    log:
        f"{LOGS}/fastqc/{{sample}}.log"
    shell:
        "fastqc {input} -o $(dirname {output.html}) &> {log}"

rule multiqc:
    input:
        expand(f"{RESULTS}/fastqc/{{sample}}_fastqc.zip", sample=SAMPLES)
    output:
        f"{RESULTS}/multiqc/multiqc_report.html"
    log:
        f"{LOGS}/multiqc/multiqc.log"
    shell:
        "multiqc {input} -o $(dirname {output}) &> {log}"

# Taxonomic profiling
rule kraken2:
    input:
        r1="data/raw/{sample}_1.fastq.gz",
        r2="data/raw/{sample}_2.fastq.gz"
    output:
        report=f"{RESULTS}/kraken2/{{sample}}_kraken2.report",
        out=f"{RESULTS}/kraken2/{{sample}}_kraken2.out"
    log:
        f"{LOGS}/kraken2/{{sample}}.log"
    shell:
        "kraken2 --paired --db {config[kraken2_db]} \
        --report {output.report} \
        --output {output.out} \
        {input.r1} {input.r2} &> {log}"

rule metaphlan:
    input:
        r1="data/raw/{sample}_1.fastq.gz",
        r2="data/raw/{sample}_2.fastq.gz"
    output:
        profile=f"{RESULTS}/metaphlan/{{sample}}_profile.txt"
    log:
        f"{LOGS}/metaphlan/{{sample}}.log"
    shell:
        "metaphlan {input.r1},{input.r2} \
        --input_type fastq \
        --nproc 4 \
        --output_file {output.profile} &> {log}"

# Functional annotation
rule humann:
    input:
        r1="data/raw/{sample}_1.fastq.gz",
        r2="data/raw/{sample}_2.fastq.gz"
    output:
        genefamilies=f"{RESULTS}/humann/{{sample}}_genefamilies.tsv",
        pathcoverage=f"{RESULTS}/humann/{{sample}}_pathcoverage.tsv",
        pathabundance=f"{RESULTS}/humann/{{sample}}_pathabundance.tsv"
    log:
        f"{LOGS}/humann/{{sample}}.log"
    shell:
        "cat {input.r1} {input.r2} | \
        humann --input - \
        --output $(dirname {output.genefamilies}) \
        --threads 4 &> {log}"