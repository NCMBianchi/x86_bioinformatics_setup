# x86 Bioinformatics Setup
This script installs all dependencies necessary to manage different Python versions via Pyenv and Conda, in order to use bioinformatics tools that require x86_64 architecture and thus do not work on arm64 (Apple Silicon, M1-M3 processors).

![bioinformatics-BANNER](https://github.com/user-attachments/assets/60abeabd-1a83-46e4-803f-83b71380da56)

## Features
- Allows to run packages such as [bowtie](https://anaconda.org/bioconda/bowtie) and [macs2](https://anaconda.org/bioconda/macs2) that are not –or not fully– supported in arm64.
- Installs the 2.2.2. version of [PyTorch](https://pytorch.org/get-started/previous-versions/) and its dependencies.
- Installs [R](https://www.r-project.org) to run scripts locally within hybrid pipelines, but not [Rstudio](https://posit.co/downloads/) which only recognises the default R version (check the [Rig](https://github.com/r-lib/rig) repository to manage different versions of R in Rstudio).

![BIOINFORMATICS_pipeline](https://github.com/user-attachments/assets/3f00be49-bf84-49c7-993e-0e9420ab4909)

## Installation
Clone this repository, move into it and activate the scritp with:
```
chmod +x ./arm64_setup.sh
```
Then run it with:
```
./arm64_setup.sh
```
Installing it might take a while. It takes care also of installing [homebrew](https://brew.sh) if it's not already installed. I highly suggested using it to install any tool that is required even within virtual environments. This script assumes ZSH as the currently used shell, yet the `--fish` parameters allows to instead set up according to the [fish shell](https://fishshell.com).

## License
This project is licensed under the MIT License. Feel free to use and modify the code as per your needs.
