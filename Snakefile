import os
from pathlib import Path

# Configuration
configfile: "config/config.yaml"

# Global variables
SAMPLES = config["samples"]
RESULTS = "results"
LOGS = "logs"

# Rules
rule all:
    input:
        # Quality Control
        expand(f"{RESULTS}/fastqc/{{sample}}_fastqc.html", sample=SAMPLES),
        f"{RESULTS}/multiqc/multiqc_report.html",
        # Processed reads
        expand(f"{RESULTS}/trimmed/{{sample}}_trimmed_1.fastq.gz", sample=SAMPLES),
        expand(f"{RESULTS}/trimmed/{{sample}}_trimmed_2.fastq.gz", sample=SAMPLES),
        # Host removal
        expand(f"{RESULTS}/host_removed/{{sample}}_host_removed_1.fastq.gz", sample=SAMPLES),
        # Taxonomic profiling
        expand(f"{RESULTS}/kraken2/{{sample}}_kraken2.report", sample=SAMPLES),
        expand(f"{RESULTS}/metaphlan/{{sample}}_profile.txt", sample=SAMPLES),
        # Functional profiling
        expand(f"{RESULTS}/humann/{{sample}}_genefamilies.tsv", sample=SAMPLES),
        # Final report
        f"{RESULTS}/final_report.html"

# Quality Control
rule fastqc:
    input:
        r1 = "data/{sample}_1.fastq.gz",
        r2 = "data/{sample}_2.fastq.gz"
    output:
        html = f"{RESULTS}/fastqc/{{sample}}_fastqc.html",
        zip = f"{RESULTS}/fastqc/{{sample}}_fastqc.zip"
    log:
        f"{LOGS}/fastqc/{{sample}}.log"
    threads: 4
    shell:
        """
        fastqc {input.r1} {input.r2} \
            --outdir $(dirname {output.html}) \
            --threads {threads} \
            2> {log}
        """

rule multiqc:
    input:
        expand(f"{RESULTS}/fastqc/{{sample}}_fastqc.zip", sample=SAMPLES)
    output:
        f"{RESULTS}/multiqc/multiqc_report.html"
    log:
        f"{LOGS}/multiqc/multiqc.log"
    shell:
        """
        multiqc {input} \
            --outdir $(dirname {output}) \
            2> {log}
        """

# Read Trimming
rule trimmomatic:
    input:
        r1 = "data/{sample}_1.fastq.gz",
        r2 = "data/{sample}_2.fastq.gz"
    output:
        r1 = f"{RESULTS}/trimmed/{{sample}}_trimmed_1.fastq.gz",
        r2 = f"{RESULTS}/trimmed/{{sample}}_trimmed_2.fastq.gz"
    log:
        f"{LOGS}/trimmomatic/{{sample}}.log"
    threads: 8
    shell:
        """
        trimmomatic PE \
            -threads {threads} \
            {input.r1} {input.r2} \
            {output.r1} {output.r1}.unpaired \
            {output.r2} {output.r2}.unpaired \
            ILLUMINACLIP:{config[adapter_file]}:2:30:10 \
            LEADING:3 TRAILING:3 \
            SLIDINGWINDOW:4:15 \
            MINLEN:36 \
            2> {log}
        """

# Host Removal
rule remove_host:
    input:
        r1 = f"{RESULTS}/trimmed/{{sample}}_trimmed_1.fastq.gz",
        r2 = f"{RESULTS}/trimmed/{{sample}}_trimmed_2.fastq.gz"
    output:
        r1 = f"{RESULTS}/host_removed/{{sample}}_host_removed_1.fastq.gz",
        r2 = f"{RESULTS}/host_removed/{{sample}}_host_removed_2.fastq.gz"
    log:
        f"{LOGS}/host_removal/{{sample}}.log"
    threads: 8
    shell:
        """
        bowtie2 \
            -x {config[host_genome]} \
            -1 {input.r1} -2 {input.r2} \
            --threads {threads} \
            --un-conc-gz {output.r1} \
            2> {log}
        """

# Taxonomic Profiling
rule kraken2:
    input:
        r1 = f"{RESULTS}/host_removed/{{sample}}_host_removed_1.fastq.gz",
        r2 = f"{RESULTS}/host_removed/{{sample}}_host_removed_2.fastq.gz"
    output:
        report = f"{RESULTS}/kraken2/{{sample}}_kraken2.report",
        out = f"{RESULTS}/kraken2/{{sample}}_kraken2.out"
    log:
        f"{LOGS}/kraken2/{{sample}}.log"
    threads: 8
    shell:
        """
        kraken2 \
            --db {config[kraken2_db]} \
            --threads {threads} \
            --paired \
            --output {output.out} \
            --report {output.report} \
            {input.r1} {input.r2} \
            2> {log}
        """

rule metaphlan:
    input:
        r1 = f"{RESULTS}/host_removed/{{sample}}_host_removed_1.fastq.gz",
        r2 = f"{RESULTS}/host_removed/{{sample}}_host_removed_2.fastq.gz"
    output:
        profile = f"{RESULTS}/metaphlan/{{sample}}_profile.txt"
    log:
        f"{LOGS}/metaphlan/{{sample}}.log"
    threads: 8
    shell:
        """
        metaphlan \
            {input.r1},{input.r2} \
            --input_type fastq \
            --nproc {threads} \
            --bowtie2db {config[metaphlan_db]} \
            -o {output.profile} \
            2> {log}
        """

# Functional Profiling
rule humann:
    input:
        r1 = f"{RESULTS}/host_removed/{{sample}}_host_removed_1.fastq.gz",
        r2 = f"{RESULTS}/host_removed/{{sample}}_host_removed_2.fastq.gz"
    output:
        genefamilies = f"{RESULTS}/humann/{{sample}}_genefamilies.tsv",
        pathways = f"{RESULTS}/humann/{{sample}}_pathways.tsv",
        pathcoverage = f"{RESULTS}/humann/{{sample}}_pathcoverage.tsv"
    log:
        f"{LOGS}/humann/{{sample}}.log"
    threads: 8
    shell:
        """
        humann \
            --input-1 {input.r1} \
            --input-2 {input.r2} \
            --threads {threads} \
            --output-basename {wildcards.sample} \
            --output {RESULTS}/humann \
            --nucleotide-database {config[chocophlan_db]} \
            --protein-database {config[uniref_db]} \
            2> {log}
        """