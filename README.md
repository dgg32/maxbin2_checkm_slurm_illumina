
# maxbin2_checkm_slurm_illumina
Slurm workflow for metagnomic binning in DSMZ. This script relies on the slurm scheduler to orchestrate the computer resources. It put together several bioinformatic tools and has add an important step in the middle: to filter the primer-dimers ("carp" sequences).


## Prerequisites

Slurm

Sickle

Megahit

Maxbin

Bowtie2

Samtools

MetaBat

Concoct

Checkm

DAS Tool

All the pipeline specific tools have been already installed in the "binning" environment in DSMZ. To use the binning environment. Add the following two lines in your ~/.condarc

    envs_dirs:
      - /opt/hpcopt/sixing/anaconda3/envs

You may need to restart the terminal to proceed.

Afterwards to test whether the environment is available, activate the "binning" environment by issuing the following command in terminal

    conda activate binning


## Installing

Scripts can be run as is without installation.


## Run

0. activate the binning environment by issuing the following command in terminal:

    conda activate binning

1. cd into this script folder

2. ./submit.sh [metagenome folder]

After all the metagenomes are processed, we can then compile the chechm results:

3. find [metagenome folder] -type d -name "*_checkm" -printf "%f\n\n" -exec python checkm_compilor_general.py {} \; > chechm_summary.txt

## Authors

* **Sixing Huang** - *Concept and Coding*

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
