#!/bin/bash

# Exit on error
set -e

# Default values
SHELL_TYPE="zsh"
FORCE_PLATFORM=""
FORCE_ARCH=""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --fish)
            SHELL_TYPE="fish"
            shift
            ;;
        --force-platform=*)
            FORCE_PLATFORM="${arg#*=}"
            shift
            ;;
        --force-arch=*)
            FORCE_ARCH="${arg#*=}"
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --fish                    Use fish shell configuration (default: zsh)"
            echo "  --force-platform=PLATFORM Force platform (darwin/linux)"
            echo "  --force-arch=ARCH        Force architecture (x86_64/arm64)"
            echo "  --help                   Show this help message"
            exit 0
            ;;
    esac
done

# Detect platform and architecture
detect_platform() {
    if [[ -n "$FORCE_PLATFORM" ]]; then
        echo "$FORCE_PLATFORM"
    else
        uname | tr '[:upper:]' '[:lower:]'
    fi
}

detect_arch() {
    if [[ -n "$FORCE_ARCH" ]]; then
        echo "$FORCE_ARCH"
    else
        uname -m
    fi
}

detect_linux_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

PLATFORM=$(detect_platform)
ARCH=$(detect_arch)

# Normalize architecture names
if [[ "$ARCH" == "aarch64" ]]; then
    ARCH="arm64"
elif [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "amd64" ]]; then
    ARCH="x86_64"
fi

echo -e "${GREEN}Starting installation process...${NC}"
echo -e "${YELLOW}Detected platform: $PLATFORM${NC}"
echo -e "${YELLOW}Detected architecture: $ARCH${NC}"
echo -e "${YELLOW}Shell configuration: $SHELL_TYPE${NC}"

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
        # Zsh/Bash shell configuration
        local shell_rc=""
        if [[ "$SHELL_TYPE" == "zsh" ]]; then
            shell_rc="$HOME/.zshrc"
        else
            shell_rc="$HOME/.bashrc"
        fi

        if [[ -f "$shell_rc" ]] && ! grep -q "$config_line" "$shell_rc" 2>/dev/null; then
            echo "$config_line" >> "$shell_rc"
        elif [[ ! -f "$shell_rc" ]]; then
            echo "$config_line" >> "$shell_rc"
        fi
    fi
}

# Platform-specific package manager installation
install_package_manager() {
    case "$PLATFORM" in
        darwin)
            # Install Homebrew if not installed
            if ! command -v brew &> /dev/null; then
                echo -e "${GREEN}Installing Homebrew...${NC}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

                # Configure Homebrew path based on architecture
                if [[ "$ARCH" == "arm64" ]]; then
                    setup_shell_config 'export PATH="/opt/homebrew/bin:$PATH"'
                    export PATH="/opt/homebrew/bin:$PATH"
                else
                    setup_shell_config 'export PATH="/usr/local/bin:$PATH"'
                    export PATH="/usr/local/bin:$PATH"
                fi
            fi
            ;;
        linux)
            DISTRO=$(detect_linux_distro)
            case "$DISTRO" in
                arch|manjaro|endeavouros)
                    echo -e "${GREEN}Arch-based distribution detected${NC}"
                    # Update package database
                    sudo pacman -Sy --noconfirm
                    ;;
                ubuntu|debian)
                    echo -e "${RED}Ubuntu/Debian detected but not yet supported${NC}"
                    echo "This script currently supports macOS and Arch-based Linux distributions only."
                    echo "For Ubuntu/Debian, package manager integration would require apt-get commands."
                    exit 1
                    ;;
                fedora|rhel|centos)
                    echo -e "${RED}Red Hat-based distribution detected but not yet supported${NC}"
                    echo "This script currently supports macOS and Arch-based Linux distributions only."
                    echo "For Red Hat-based systems, package manager integration would require dnf/yum commands."
                    exit 1
                    ;;
                *)
                    echo -e "${RED}Unsupported Linux distribution: $DISTRO${NC}"
                    echo "This script currently supports macOS and Arch-based Linux distributions only."
                    exit 1
                    ;;
            esac
            ;;
        *)
            echo -e "${RED}Unsupported platform: $PLATFORM${NC}"
            exit 1
            ;;
    esac
}

# Install pyenv
install_pyenv() {
    echo -e "${GREEN}Installing pyenv...${NC}"

    case "$PLATFORM" in
        darwin)
            brew install pyenv
            ;;
        linux)
            if command -v pacman &> /dev/null; then
                # Install dependencies for building Python
                sudo pacman -S --needed --noconfirm base-devel openssl zlib xz tk

                # Install pyenv from AUR or manually
                if ! command -v pyenv &> /dev/null; then
                    curl https://pyenv.run | bash
                fi
            fi
            ;;
    esac

    # Add pyenv to shell configuration
    if [[ "$SHELL_TYPE" == "fish" ]]; then
        setup_shell_config 'set -gx PATH "$HOME/.pyenv/bin" $PATH'
        setup_shell_config 'status --is-interactive; and pyenv init - | source'
        setup_shell_config 'status --is-interactive; and pyenv virtualenv-init - | source'
    else
        setup_shell_config 'export PYENV_ROOT="$HOME/.pyenv"'
        setup_shell_config 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"'
        setup_shell_config 'eval "$(pyenv init -)"'
    fi

    # Activate for current session
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
}

# Install conda/miniconda
install_conda() {
    if ! command -v conda &> /dev/null; then
        echo -e "${GREEN}Installing conda...${NC}"

        case "$PLATFORM" in
            darwin)
                brew install --cask miniconda
                CONDA_BASE="/opt/homebrew/Caskroom/miniconda/base"
                if [[ ! -d "$CONDA_BASE" ]]; then
                    CONDA_BASE="/usr/local/Caskroom/miniconda/base"
                fi
                ;;
            linux)
                # Download and install Miniconda for Linux
                if [[ "$ARCH" == "x86_64" ]]; then
                    MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
                elif [[ "$ARCH" == "arm64" ]] || [[ "$ARCH" == "aarch64" ]]; then
                    MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh"
                else
                    echo -e "${RED}Unsupported architecture for Linux: $ARCH${NC}"
                    exit 1
                fi

                curl -fsSL -o /tmp/miniconda.sh "$MINICONDA_URL"
                bash /tmp/miniconda.sh -b -p "$HOME/miniconda3"
                rm /tmp/miniconda.sh
                CONDA_BASE="$HOME/miniconda3"
                ;;
        esac

        # Initialize conda for the appropriate shell
        if [[ "$SHELL_TYPE" == "fish" ]]; then
            "$CONDA_BASE/bin/conda" init fish
        else
            "$CONDA_BASE/bin/conda" init "$SHELL_TYPE"
        fi

        # Add conda to PATH for current session
        export PATH="$CONDA_BASE/bin:$PATH"
    else
        # Conda exists - check if it's system-wide
        CONDA_PATH=$(which conda)
        CONDA_BASE=$(dirname $(dirname "$CONDA_PATH"))

        if [[ "$CONDA_BASE" == "/opt"* ]] || [[ "$CONDA_BASE" == "/usr"* ]]; then
            echo -e "${YELLOW}Warning: System-wide conda installation detected at $CONDA_BASE${NC}"
            echo -e "${YELLOW}You may need sudo privileges to install packages.${NC}"
            echo -e "${YELLOW}Consider installing a user-specific conda in $HOME/miniconda3${NC}"
            echo -e "${YELLOW}To do this, uninstall system conda or use a different user.${NC}"
        else
            echo -e "${GREEN}Using existing conda installation at $CONDA_BASE${NC}"
        fi
    fi
}

# Determine conda architecture subdirectory
get_conda_subdir() {
    case "$PLATFORM-$ARCH" in
        darwin-x86_64)
            echo "osx-64"
            ;;
        darwin-arm64)
            echo "osx-arm64"
            ;;
        linux-x86_64)
            echo "linux-64"
            ;;
        linux-arm64|linux-aarch64)
            echo "linux-aarch64"
            ;;
        *)
            echo -e "${RED}Unsupported platform-architecture combination: $PLATFORM-$ARCH${NC}"
            exit 1
            ;;
    esac
}

# Main installation process
main() {
    # Install package manager
    install_package_manager

    # Install pyenv
    install_pyenv

    # Install Python versions
    echo -e "${GREEN}Installing Python versions...${NC}"
    pyenv install -s 3.12.6
    pyenv install -s 3.9.7

    # Set global Python version
    echo -e "${GREEN}Setting Python 3.12.6 as global...${NC}"
    pyenv global 3.12.6

    # Install conda
    install_conda

    # Initialize conda for current session
    if command -v conda &> /dev/null; then
        eval "$(conda shell.bash hook)"
    else
        echo -e "${RED}Conda installation failed or not in PATH${NC}"
        exit 1
    fi

    # Determine conda subdirectory
    CONDA_SUBDIR=$(get_conda_subdir)
    echo -e "${GREEN}Using conda subdirectory: $CONDA_SUBDIR${NC}"

    # Create conda environment for bioinformatics
    echo -e "${GREEN}Creating conda environment for bioinformatics...${NC}"

    # For x86 emulation on ARM Macs, we need to use osx-64
    if [[ "$PLATFORM" == "darwin" ]] && [[ "$ARCH" == "arm64" ]]; then
        echo -e "${YELLOW}Note: On ARM Mac, creating x86_64 environment for compatibility${NC}"
        CONDA_SUBDIR="osx-64"
    fi

    # Check if bioinformatics environment already exists
    if conda env list | grep -q "^bioinformatics "; then
        echo -e "${YELLOW}Conda environment 'bioinformatics' already exists. Skipping creation...${NC}"
    else
        CONDA_SUBDIR=$CONDA_SUBDIR conda create -n bioinformatics python=3.9 -y
    fi

    # Activate environment and set architecture
    conda activate bioinformatics
    conda config --env --set subdir $CONDA_SUBDIR

    # Install bioinformatics packages
    echo -e "${GREEN}Installing bioinformatics packages and dependencies...${NC}"

    # Core bioinformatics tools
    conda install -y \
        bioconda::bedtools \
        bioconda::bowtie \
        bioconda::bowtie2 \
        bioconda::bwa \
        bioconda::freebayes \
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
    conda install -y -c conda-forge ncbi-datasets-cli

    # Install snakemake with conda-forge channel for dependencies
    echo -e "${GREEN}Installing Snakemake workflow manager...${NC}"
    conda install -y -c conda-forge -c bioconda snakemake-minimal

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

    # PyTorch and related packages (platform-specific)
    if [[ "$PLATFORM" == "darwin" ]] && [[ "$ARCH" == "arm64" ]]; then
        # For ARM Macs, PyTorch might need special handling
        echo -e "${YELLOW}Installing PyTorch for ARM Mac (may use CPU version)${NC}"
    fi

    conda install -y \
        pytorch::torch=2.2.2 \
        pytorch::torchvision \
        conda-forge::torchsde

    # R and R packages
    echo -e "${GREEN}Installing R and R packages...${NC}"
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

    # Set up the kernel for Jupyter
    python -m ipykernel install --user --name=bioinformatics --display-name="Bioinformatics"

    echo -e "${GREEN}Setup complete!${NC}"
    echo -e "${YELLOW}To activate the bioinformatics environment, restart your terminal and then run:${NC}"
    echo -e "${GREEN}conda activate bioinformatics${NC}"

    # Platform-specific notes
    if [[ "$PLATFORM" == "darwin" ]] && [[ "$ARCH" == "arm64" ]]; then
        echo -e "${YELLOW}Note: You're running on ARM Mac. The environment uses x86_64 packages via Rosetta 2 emulation for compatibility.${NC}"
    fi
}

# Run main installation
main
