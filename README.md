# x86 Bioinformatics Setup
This script installs all dependencies necessary to manage different Python versions via Pyenv and Conda, in order to use bioinformatics tools that require x86_64 architecture. Originally designed for ARM64 Macs (Apple Silicon, M1-M3 processors), it now supports multiple platforms and architectures.

![bioinformatics-BANNER](https://github.com/user-attachments/assets/dc32542b-946a-47a6-b6a2-75adb0d8cc14)

## Features
- **Multi-platform support**: Works on macOS (both ARM64 and x86_64) and Linux (Arch-based distributions)
- **Automatic detection**: Detects OS and architecture automatically
- **Force options**: Can force specific platform/architecture configurations
- Allows to run packages such as [bowtie](https://anaconda.org/bioconda/bowtie) and [macs2](https://anaconda.org/bioconda/macs2) that are not –or not fully– supported in arm64
- Installs [R](https://www.r-project.org) to run scripts locally within hybrid pipelines, but not [Rstudio](https://posit.co/downloads/) which only recognises the default R version (check the [Rig](https://github.com/r-lib/rig) repository to manage different versions of R in Rstudio)
- Automatically installs Bioconductor packages (DESeq2, edgeR, etc.) within the conda environment using BiocManager

<img width="4088" height="4388" alt="BIOINFORMATICS_pipeline (2)" src="https://github.com/user-attachments/assets/cbcd5b9c-d8b1-4fc2-bbf2-3500c061dd16" />

## Supported Platforms

| Platform | Architecture | Status | Notes |
|----------|-------------|--------|--------|
| macOS | ARM64 (M1-M3) | ✅ Supported | Uses Rosetta 2 for x86_64 packages |
| macOS | x86_64 | ✅ Supported | Native support |
| Linux | x86_64 | ✅ Supported | Arch-based distros only |
| Linux | ARM64 | ✅ Supported | Arch-based distros only |
| Ubuntu/Debian | Any | ⚠️ Not yet supported | Would require apt-get integration |
| RHEL/Fedora | Any | ⚠️ Not yet supported | Would require dnf/yum integration |

## Installation

### Basic Installation
Clone this repository, move into it and make the script executable:
```bash
git clone <repository-url>
cd x86_bioinformatics_setup
chmod +x ./multiplatform_setup.sh
```

Then run it with:
```bash
./multiplatform_setup.sh
```

### Installation Options

The script supports several command-line options:

```bash
# Use fish shell configuration instead of zsh (default)
./multiplatform_setup.sh --fish

# Force specific platform (useful for testing or containers)
./multiplatform_setup.sh --force-platform=linux

# Force specific architecture
./multiplatform_setup.sh --force-arch=x86_64

# Combine multiple options
./multiplatform_setup.sh --fish --force-platform=darwin --force-arch=arm64

# Show help
./multiplatform_setup.sh --help
```

### Platform-Specific Notes

#### macOS (ARM64/Apple Silicon)
- The script will automatically use Rosetta 2 to run x86_64 bioinformatics packages
- Homebrew will be installed if not present
- Conda environment uses `osx-64` subdirectory for compatibility

#### macOS (x86_64/Intel)
- Native support for all packages
- Homebrew will be installed if not present
- Conda environment uses native `osx-64` subdirectory

#### Linux (Arch-based)
- Supports Arch Linux, Manjaro, EndeavourOS, and other Arch-based distributions
- Uses `pacman` for system dependencies
- Pyenv is installed via the official installer script
- Miniconda is downloaded and installed to `$HOME/miniconda3`

#### Unsupported Linux Distributions
If you're using a non-Arch-based Linux distribution, the script will detect this and provide an informative error message. Support for other distributions can be added by extending the package manager detection logic.

## What Gets Installed

### Package Managers & Environment Tools
- **Homebrew** (macOS only)
- **Pyenv** for Python version management
- **Miniconda** for conda environment management

### Python Versions
- Python 3.12.6 (set as global)
- Python 3.9.7 (for bioinformatics environment)

### Bioinformatics Tools
Core tools installed via conda-forge and bioconda:
- bedtools, bowtie, bowtie2, bwa
- hisat2, multiqc, samtools, qualimap
- fastqc, macs2, stringtie, vcftools, kallisto
- snakemake (workflow management system)
- NCBI datasets CLI

### Scientific Python Packages
- NumPy, Pandas, SciPy, scikit-learn
- Jupyter, IPython kernel
- Scanpy, HTSeq

### R and R Packages
- R base and essentials
- BiocManager for package management
- tidyverse, ggplot2, dplyr
- Seurat
- **Bioconductor packages** (installed via BiocManager within conda environment):
  - DESeq2, edgeR, limma (RNA-seq differential expression)
  - Rsubread (read alignment and counting)
  - recount3 (access to RNA-seq databases)

## Shell Configuration

The script automatically configures your shell. Supported shells:
- **Zsh** (default on modern macOS)
- **Bash** (common on Linux)
- **Fish** (use `--fish` flag)

After installation, restart your terminal or source your shell configuration:
```bash
# For zsh
source ~/.zshrc

# For bash
source ~/.bashrc

# For fish
source ~/.config/fish/config.fish
```

## Usage

After installation, activate the bioinformatics environment:
```bash
conda activate bioinformatics
```

To deactivate:
```bash
conda deactivate
```

## Troubleshooting

### Platform Detection Issues
If the script incorrectly detects your platform or architecture, use the force options:
```bash
./multiplatform_setup.sh --force-platform=linux --force-arch=x86_64
```

### Conda Environment Issues
If packages fail to install due to architecture conflicts, the script will automatically handle the conda subdirectory configuration. For manual fixes:
```bash
conda config --env --set subdir osx-64  # For x86_64 on Mac
conda config --env --set subdir linux-64  # For x86_64 on Linux
```

### Bioconductor Package Installation
Some Bioconductor packages (DESeq2, edgeR, limma, etc.) are automatically installed within the conda environment using BiocManager during setup. This approach is used because conda recipes for these packages are outdated and require ancient R versions. If any fail during setup, you can manually install them:
```bash
conda activate bioinformatics
Rscript install_r_packages.R
# Or within R:
BiocManager::install(c("DESeq2", "edgeR", "limma"))
```

### Missing Dependencies on Linux
For Arch-based systems, ensure your system is up-to-date:
```bash
sudo pacman -Syu
```

## Legacy Script

The original ARM64-only script (`arm64_setup.sh`) has been deprecated in favor of the new multi-platform `multiplatform_setup.sh`. While the file is preserved locally for backwards compatibility, it is no longer tracked in version control. Please use `multiplatform_setup.sh` for all new installations.

## License
This project is licensed under the MIT License. Feel free to use and modify the code as per your needs.
