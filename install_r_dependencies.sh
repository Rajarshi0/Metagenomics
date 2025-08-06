#!/bin/bash

# Install R dependencies for the report generation
R -e '
    if (!requireNamespace("BiocManager", quietly = TRUE))
        install.packages("BiocManager")
    
    # Install required packages
    packages <- c(
        "rmarkdown",
        "knitr",
        "ggplot2",
        "dplyr",
        "plotly",
        "yaml"
    )
    
    for (pkg in packages) {
        if (!requireNamespace(pkg, quietly = TRUE))
            install.packages(pkg)
    }
    
    # Install Bioconductor packages
    BiocManager::install(c("phyloseq"), update = FALSE)
'