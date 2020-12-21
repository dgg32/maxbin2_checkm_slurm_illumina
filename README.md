# maxbin2_checkm_slurm_illumina
Slurm workflow for metagnomic binning in DSMZ. This script relies on the slurm scheduler to orchestrate the computer resources. It put together several bioinformatic tools and has add an important step in the middle: to filter the primer-dimers ("carp" sequences).


## Prerequisites

Slurm

Sickle

Megahit

Maxbin

MetaBat

Concoct

Checkm

DAS Tool




## Installing

Scripts can be run as is without installation.


## Run

1. cd into this script folder

2. ./submit.sh [metagenome folder]

After all the metagenomes are processed, we can then compile the chechm results:

3. find [metagenome folder] -type d -name "*_checkm" -printf "%f\n\n" -exec python checkm_compilor_general.py {} \; > chechm_summary.txt

## Authors

* **Sixing Huang** - *Concept and Coding*

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
