#!/bin/bash



R1=$(find $1 -maxdepth 1 -regex '\S+fastq'  -not -name "*trimmed*" | grep "R1" | head -n $SLURM_ARRAY_TASK_ID | tail -n 1)


R2=${R1/R1/"R2"}

R1trim=${R1/.fastq/"_trimmed.fastq"}
R2trim=${R2/.fastq/"_trimmed.fastq"}
single=${R1/.fastq/"_single_trimmed.fastq"}
single=${single/R1/""}

R1_no_carp=${R1/.fastq/"_trimmed_no_carp.fastq"}
R2_no_carp=${R2/.fastq/"_trimmed_no_carp.fastq"}

megahitout=${single/_single_trimmed.fastq/"_megahit"}

maxbinoutfolder=${single/_single_trimmed.fastq/"_maxbin"}
checkmfolder=${single/_single_trimmed.fastq/"_checkm"}

maxbinout=$maxbinoutfolder"/maxbin"

cores=$2


if [ ! -f $R1trim ];
then
/home/sih13/tool/sickle-master/sickle pe -f $R1 -r $R2 -o $R1trim -p $R2trim -s $single --quiet -t sanger
fi


if [ ! -f $R1_no_carp ];
then
python filter_fasta_multiprocess_big.py './taboo.txt' $R1trim $cores
fi


if [ ! -d $megahitout ];
then
megahit -1 $R1_no_carp -2 $R2_no_carp -o $megahitout -t $cores
fi


if [ ! -d $maxbinoutfolder ];
then
mkdir $maxbinoutfolder

run_MaxBin.pl -contig $megahitout/final.contigs.fa -out $maxbinout  -reads $R1_no_carp -reads2 $R2_no_carp -thread $cores -min_contig_length 200
fi


if [ ! -d $checkmfolder ];
then

source ~/anaconda3/etc/profile.d/conda.sh

conda activate checkm

checkm  lineage_wf -t $cores -x fasta $maxbinoutfolder $checkmfolder
fi
