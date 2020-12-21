#!/bin/bash

inputfolder=$1
projectname=$(basename "${inputfolder}")

cpu=28

R1s=$(find $inputfolder -maxdepth 1 -regex '\S+fastq'  -not -name "*trimmed*" | grep "R1")

R1_list=""
R2_list=""
total_list=""

for R1 in $R1s;
do
	R2=${R1/R1/"R2"}
	#printf "$R1\n$R2\n"
	R1trim=${R1/.fastq/"_trimmed.fastq"}
	R2trim=${R2/.fastq/"_trimmed.fastq"}
	single=${R1/.fastq/"_single_trimmed.fastq"}
	single=${single/R1/""}

	R1_no_carp=${R1/.fastq/"_trimmed_no_carp.fastq"}
	R2_no_carp=${R2/.fastq/"_trimmed_no_carp.fastq"}

	if [ ! -f $R1trim ];
	then
		/home/sih13/tool/sickle-master/sickle pe -f $R1 -r $R2 -o $R1trim -p $R2trim -s $single --quiet -t sanger
	fi


	if [ ! -f $R1_no_carp ];
	then
		python filter_fasta_multiprocess.py './taboo.txt' $R1trim $cpu
	fi

	R1_list="${R1_list},$R1_no_carp"
	R2_list="${R2_list},$R2_no_carp"
	total_list="${total_list}\n$R1_no_carp\n$R2_no_carp"


done

R1_list="${R1_list:1}"
R2_list="${R2_list:1}"
total_list="${total_list:2}"

megahitout="${inputfolder}/{projectname}_mix_megahit"



if [ ! -d $megahitout ];
then
megahit -1 $R1_list -2 $R2_list -o $megahitout -t $cpu
fi

maxbinoutfolder="${inputfolder}/{projectname}_mix_maxbin"

maxbinout=$maxbinoutfolder"/maxbin"
readlistfile="${inputfolder}/read_list_file.txt"


if [ ! -d $maxbinoutfolder ];
then
mkdir $maxbinoutfolder

printf $total_list > $readlistfile

run_MaxBin.pl -contig $megahitout/final.contigs.fa -out $maxbinout  -reads_list $readlistfile -thread $cpu -min_contig_length 200
fi


checkmfolder="${inputfolder}/{projectname}_mix_checkm"

if [ ! -d $checkmfolder ];
then

source ~/anaconda3/etc/profile.d/conda.sh

conda activate checkm

checkm  lineage_wf -t $cpu -x fasta $maxbinoutfolder $checkmfolder
fi