#!/bin/bash

#qsub -tc 30 -e /home/sih13/sge-log-files/ -o $1 -t 1-$(find $1 -maxdepth 1 -name "*.fasta_*"|wc -l) importer.sh $1

find $1 -maxdepth 1 -regex '\S+fastq.gz' -exec gunzip {} \;



sbatch -c 28 --mem=230G -p mid --error $1/slurm-%A_%a.error.txt --output $1/output.txt importer_multi_in_one.sh $1
