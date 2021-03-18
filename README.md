

# maxbin2_checkm_slurm_illumina
Slurm workflow for metagnomic binning in DSMZ. This script relies on the slurm scheduler to orchestrate the computer resources. It put together several bioinformatic tools and has add an important step in the middle: to filter the primer-dimers ("carp" sequences).


## Prerequisites

 - Slurm
   
  - Sickle
   
  - Megahit
   
 - Maxbin2
   
 - Bowtie2
   
 - Samtools
   
 - MetaBat2
   
 - Concoct
 - Checkm

 - DAS Tool

All the pipeline specific tools have been already installed in the "binning" environment in DSMZ. To use the binning environment. Add the following two lines in your ~/.condarc

    envs_dirs:
      - /opt/hpcopt/sixing/anaconda3/envs

You may need to restart the terminal to proceed.

Afterwards to test whether the environment is available, activate the "binning" environment by issuing the following command in terminal

    conda activate binning


## Installing

Please compile [sickle](https://github.com/najoshi/sickle) and add it to the path.

Scripts can be run as is without installation.


## Run

0. activate the binning environment by issuing the following command in terminal:

    conda activate binning

1. cd into this script folder

2. ./submit.sh [metagenome folder]

After all the metagenomes are processed, we can then compile the chechm results:

3. find [metagenome folder] -type d -name "*_checkm" -printf "%f\n\n" -exec python checkm_compilor_general.py {} \\; > [chechm_summary_output_file]

4. find [bin folder]  \\( -name "*.fa" -o -name "*.fasta" \\) -printf "\n\n%f" -exec python bam_coverage.py [mapping_sort.bam_file]   {} \\;


## Authors

* **Sixing Huang** - *Concept and Coding*

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
