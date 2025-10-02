#!/usr/bin/env Rscript

# install_r_packages.R
# Script to install Bioconductor packages within the conda bioinformatics environment
# These packages cannot be installed via conda due to outdated recipes
# Run this AFTER activating the bioinformatics conda environment:
#   conda activate bioinformatics
#   Rscript install_r_packages.R

cat("========================================\n")
cat("Installing Bioconductor Packages\n")
cat("Within Conda Environment\n")
cat("========================================\n\n")

# Check if we're in a conda environment
conda_prefix <- Sys.getenv("CONDA_PREFIX")
if (conda_prefix == "") {
  cat("WARNING: Not in a conda environment!\n")
  cat("Please activate the bioinformatics environment first:\n")
  cat("  conda activate bioinformatics\n\n")
  cat("Continue anyway? (y/n): ")
  response <- readline()
  if (tolower(response) != "y") {
    cat("Installation cancelled.\n")
    quit(save = "no")
  }
} else {
  cat("✓ Using conda environment:", conda_prefix, "\n")
  cat("✓ Packages will be installed in:", .libPaths()[1], "\n\n")
}

# Install BiocManager if not already installed
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  cat("Installing BiocManager...\n")
  install.packages("BiocManager", repos = "https://cloud.r-project.org")
}

# Check BiocManager version
cat("BiocManager version:", as.character(BiocManager::version()), "\n")
cat("R version:", R.version.string, "\n\n")

# Core RNA-seq packages
packages_to_install <- c(
  "DESeq2", # Differential expression analysis
  "edgeR", # Alternative differential expression
  "limma", # Linear models for microarray/RNA-seq
  "Rsubread", # Read alignment and counting
  "recount3" # Access to recount3 database
)

# Install packages
cat("Installing packages (this may take 5-10 minutes)...\n\n")

for (pkg in packages_to_install) {
  cat(sprintf("Installing %s...\n", pkg))

  # Check if already installed
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("  ✓ %s is already installed\n", pkg))
  } else {
    # Try to install
    tryCatch(
      {
        BiocManager::install(pkg, update = FALSE, ask = FALSE, quiet = TRUE)

        # Verify installation
        if (requireNamespace(pkg, quietly = TRUE)) {
          cat(sprintf("  ✓ %s successfully installed\n", pkg))
        } else {
          cat(sprintf("  ✗ %s installation failed\n", pkg))
        }
      },
      error = function(e) {
        cat(sprintf("  ✗ Error installing %s: %s\n", pkg, e$message))
      }
    )
  }
  cat("\n")
}

# Test loading packages
cat("========================================\n")
cat("Testing package loading...\n")
cat("========================================\n\n")

success_count <- 0
fail_count <- 0

for (pkg in packages_to_install) {
  cat(sprintf("Loading %s... ", pkg))
  if (suppressWarnings(suppressMessages(require(pkg, character.only = TRUE, quietly = TRUE)))) {
    cat("✓\n")
    success_count <- success_count + 1
  } else {
    cat("✗\n")
    fail_count <- fail_count + 1
  }
}

# Summary
cat("\n========================================\n")
cat("Installation Summary\n")
cat("========================================\n")
cat(sprintf("Successfully installed: %d/%d packages\n", success_count, length(packages_to_install)))

if (fail_count > 0) {
  cat("\nSome packages failed to install. You can try manually:\n")
  cat("  BiocManager::install('package_name', force = TRUE)\n")
} else {
  cat("\n✓ All packages installed successfully!\n")
  cat("✓ Your conda R environment is ready for RNA-seq analysis.\n")
  cat("✓ Packages are isolated in:", .libPaths()[1], "\n")
}

cat("\nTo use these packages in your analysis:\n")
cat("  1. Activate the conda environment: conda activate bioinformatics\n")
cat("  2. Start R: R\n")
cat("  3. Load packages:\n")
cat("     library(DESeq2)\n")
cat("     library(edgeR)\n")
cat("     library(limma)\n")
