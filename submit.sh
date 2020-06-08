#!/bin/bash

#qsub -tc 30 -e /home/sih13/sge-log-files/ -o $1 -t 1-$(find $1 -maxdepth 1 -name "*.fasta_*"|wc -l) importer.sh $1

find $1 -maxdepth 2 -regex '\S+fastq.gz' -exec gunzip {} \;


sbatch -c 8 --mem=230G -p long --error $1/slurm-%A_%a.error.txt --output $1/output.txt --array=1-$(find $1 -maxdepth 2 -name "*.fastq" -not -name "*trimmed*" | grep "R1" | wc -l) importer.sh $1
