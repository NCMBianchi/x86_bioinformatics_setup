#!/bin/bash

# Exit on error
set -e

# Default shell configuration
SHELL_TYPE="zsh"

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --fish)
            SHELL_TYPE="fish"
            shift
            ;;
    esac
done

echo "Starting installation process using $SHELL_TYPE shell configuration..."

# Function to setup shell configuration
setup_shell_config() {
    local config_line="$1"
    
    if [[ "$SHELL_TYPE" == "fish" ]]; then
        # Fish shell configuration
        mkdir -p ~/.config/fish
        if ! grep -q "$config_line" ~/.config/fish/config.fish 2>/dev/null; then
            echo "$config_line" >> ~/.config/fish/config.fish
        fi
    else
        # Zsh shell configuration
        if ! grep -q "$config_line" ~/.zshrc 2>/dev/null; then
            echo "$config_line" >> ~/.zshrc
        fi
    fi
}

# Check if running on macOS
if [[ $(uname) != "Darwin" ]]; then
    echo "This script is designed for macOS only"
    exit 1
fi

# Install Homebrew if not installed
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Configure Homebrew path based on architecture
    if [[ $(uname -m) == "arm64" ]]; then
        setup_shell_config 'export PATH="/opt/homebrew/bin:$PATH"'
        export PATH="/opt/homebrew/bin:$PATH"
    else
        setup_shell_config 'export PATH="/usr/local/bin:$PATH"'
        export PATH="/usr/local/bin:$PATH"
    fi
fi

# Install pyenv (python version and environment manager)
echo "Installing pyenv..."
brew install pyenv

# Add pyenv to shell configuration
if [[ "$SHELL_TYPE" == "fish" ]]; then
    setup_shell_config 'pyenv init - | source'
    setup_shell_config 'set -gx PATH "$HOME/.pyenv/bin" $PATH'
    setup_shell_config 'status --is-interactive; and pyenv init - | source'
    setup_shell_config 'status --is-interactive; and pyenv virtualenv-init - | source'
else
    setup_shell_config 'export PATH="$HOME/.pyenv/bin:$PATH"'
    setup_shell_config 'eval "$(pyenv init --path)"'
    setup_shell_config 'eval "$(pyenv init -)"'
fi

# Activate the shell configuration
if [[ "$SHELL_TYPE" == "fish" ]]; then
    echo "Shell configuration updated. Please restart your terminal or run 'source ~/.config/fish/config.fish'"
else
    echo "Shell configuration updated. Please restart your terminal or run 'source ~/.zshrc'"
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

# Install Python versions
echo "Installing Python versions..."
pyenv install 3.12.6
pyenv install 3.9.7

# Set global Python version
echo "Setting Python 3.12.6 as global..."
pyenv global 3.12.6

# Install conda if not installed
if ! command -v conda &> /dev/null; then
    echo "Installing conda..."
    brew install conda
    
    # Initialize conda for the appropriate shell
    if [[ "$SHELL_TYPE" == "fish" ]]; then
        conda init fish
        setup_shell_config 'eval "$HOME/miniconda3/bin/conda" "shell.fish" "hook" | source'
    else
        conda init zsh
        setup_shell_config 'eval "$HOME/miniconda3/bin/conda" "shell.zsh" "hook"'
    fi
    
    # Add conda to PATH for current session
    if [[ -d "$HOME/miniconda3/bin" ]]; then
        export PATH="$HOME/miniconda3/bin:$PATH"
    elif [[ -d "/opt/homebrew/Caskroom/miniconda/base/bin" ]]; then
        export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
    fi
fi

# Initialize conda for current session
if [[ "$SHELL_TYPE" == "fish" ]]; then
    eval "$(conda shell.bash hook)"
else
    eval "$(conda shell.bash hook)"
fi

# Create conda environment for bioinformatics (x86_64)
echo "Creating x86_64 conda environment for bioinformatics..."
CONDA_SUBDIR=osx-64 conda create -n bioinformatics python=3.9 -y

# Activate environment and set architecture
conda activate bioinformatics
conda config --env --set subdir osx-64

# Install python and R packages
echo "Installing bioinformatics packages and dependencies..."

# Core bioinformatics tools
#   ('tophat2' and 'cufflinks' excluded as they both need python<=2.7)
conda install -y \
    bioconda::bedtools \
    bioconda::bowtie \
    bioconda::bowtie2 \
    bioconda::bwa \
    bioconda::freebies \
    bioconda::hisat2 \
    bioconda::multiqc \
    bioconda::samtools \
    bioconda::qualimap \
    bioconda::fastqc \
    bioconda::macs2 \
    bioconda::stringtie \
    bioconda::vcftools \
    bioconda::kallisto

# NCBI datasets
conda install -c conda-forge ncbi-datasets-cli

# Python scientific packages
conda install -y \
    conda-forge::httpie \
    conda-forge::jupyter \
    conda-forge::ipykernel \
    conda-forge::molmass \
    conda-forge::networkx \
    conda-forge::numba \
    conda-forge::numpy \
    conda-forge::pandas \
    conda-forge::scikit-learn \
    conda-forge::scipy \
    conda-forge::seaborn \
    conda-forge::scanpy \
    bioconda::htseq

# PyTorch and related packages (explicitly set to 2.2.2 max as indicated in comment)
conda install -y \
    pytorch::torch=2.2.2 \
    pytorch::torchvision \
    conda-forge::torchsde

# R and R packages
conda install -y \
    conda-forge::r-base \
    conda-forge::r-essentials \
    bioconda::bioconductor \
    conda-forge::r-biocmanager \
    conda-forge::r-dplyr \
    conda-forge::r-ggplot2 \
    conda-forge::r-seurat \
    conda-forge::r-tidyverse \
    bioconda::bioconductor-recount3 \
    bioconda::bioconductor-deseq2 \
    bioconda::bioconductor-edger \
    bioconda::bioconductor-rsubread

# set up the kernel for Jupyter
python -m ipykernel install --user --name=bioinformatics --display-name="Bioinformatics"

echo "Setup complete!"
echo "To activate the bioinformatics environment, restart your terminal and then run: conda activate bioinformatics"