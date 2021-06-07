#!/bin/bash

script_folder=$(pwd)

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

	# R1_no_conta=${R1/.fastq/"_trimmed_no_carp_no_conta.fastq"}
	# R2_no_conta=${R2/.fastq/"_trimmed_no_carp_no_conta.fastq"}

	# mapping_bam=${R1/.fastq/"_trimmed_no_carp.bam"}
	# bothReadsUnmapped=${R1/.fastq/"_trimmed_no_carp_bothReadsUnmapped.bam"}
	# sort_bothReadsUnmapped=${R1/.fastq/"_trimmed_no_carp_bothReadsUnmapped_sorted.bam"}

	if [ ! -f $R1trim ];
	then
		sickle pe -f $R1 -r $R2 -o $R1trim -p $R2trim -s $single --quiet -t sanger
	fi


	if [ ! -f $R1_no_carp ];
	then
		python filter_fasta_multiprocess.py './taboo.txt' $R1trim $cpu
	fi

	# bowtie2 -x $nc_index -1 $R1_no_carp -2 $R2_no_carp -p $cpu | samtools view -bS -o $mapping_bam
	# samtools view -b -f 12 -F 256 $mapping_bam > $bothReadsUnmapped
	# samtools sort -n -@ 2 $bothReadsUnmapped -o $sort_bothReadsUnmapped
	# samtools fastq -@ 8 $sort_bothReadsUnmapped -1 $R1_no_conta -2 $R2_no_conta -0 /dev/null -s /dev/null -n



	# R1_list="${R1_list},$R1_no_conta"
	# R2_list="${R2_list},$R2_no_conta"
	# total_list="${total_list}\n$R1_no_conta\n$R2_no_conta"

	R1_list="${R1_list},$R1_no_carp"
	R2_list="${R2_list},$R2_no_carp"
	total_list="${total_list}\n$R1_no_carp\n$R2_no_carp"


done

R1_list="${R1_list:1}"
R2_list="${R2_list:1}"
total_list="${total_list:2}"

megahitout="${inputfolder}/${projectname}_mix_megahit"



if [ ! -d $megahitout ];
then
megahit -1 $R1_list -2 $R2_list -o $megahitout -t $cpu
fi

maxbinoutfolder="${inputfolder}/${projectname}_mix_maxbin"

maxbinout=$maxbinoutfolder"/maxbin"
readlistfile="${inputfolder}/read_list_file.txt"


if [ ! -d $maxbinoutfolder ];
then
mkdir $maxbinoutfolder

printf $total_list > $readlistfile

#run_MaxBin.pl -contig $megahitout/final.contigs.fa -out $maxbinout  -reads_list $readlistfile -thread $cpu -min_contig_length 200
run_MaxBin.pl -contig $megahitout/final.contigs.fa -out $maxbinout  -reads_list $readlistfile -thread $cpu

fi


bamoutfolder="${inputfolder}/${projectname}_mix_bam"
metabatoutfolder="${inputfolder}/${projectname}_mix_metabat"
concoctoutfolder="${inputfolder}/${projectname}_mix_concoct"
dasoutfolder="${inputfolder}/${projectname}_mix_das"

das_checkmfolder="${inputfolder}/${projectname}_mix_das_checkm"
maxbin_checkmfolder="${inputfolder}/${projectname}_mix_maxbin_checkm"
metabat_checkmfolder="${inputfolder}/${projectname}_mix_metabat_checkm"
concoct_checkmfolder="${inputfolder}/${projectname}_mix_concoct_checkm"




if [ ! -d $bamoutfolder ];
then
mkdir $bamoutfolder

bowtie2-build $megahitout/final.contigs.fa $megahitout/final.contigs && bowtie2 -x $megahitout/final.contigs -1 $R1_list  -2 $R2_list  | samtools view -bS -o $bamoutfolder/mapping.bam

samtools sort -o $bamoutfolder/mapping_sort.bam $bamoutfolder/mapping.bam  && samtools index $bamoutfolder/mapping_sort.bam

fi


if [ ! -d $metabatoutfolder ];
then
mkdir $metabatoutfolder

cd $metabatoutfolder

runMetaBat.sh -m 1500 $megahitout/final.contigs.fa $bamoutfolder/mapping_sort.bam

fi


if [ ! -d $concoctoutfolder ];
then
mkdir $concoctoutfolder

mkdir $concoctoutfolder/bin

cd $concoctoutfolder

cut_up_fasta.py $megahitout/final.contigs.fa -c 10000 -o 0 --merge_last -b contigs_10K.bed > contigs_10K.fa


concoct_coverage_table.py contigs_10K.bed $bamoutfolder/mapping_sort.bam > coverage_table.tsv


concoct --composition_file contigs_10K.fa --coverage_file coverage_table.tsv --threads 8

merge_cutup_clustering.py clustering_gt1000.csv > clustering_merged.csv


extract_fasta_bins.py $megahitout/final.contigs.fa clustering_merged.csv --output_path $concoctoutfolder/bin

fi


if [ ! -d $dasoutfolder ];
then
mkdir $dasoutfolder

cd $maxbinoutfolder
Fasta_to_Scaffolds2Bin.sh -e fasta > $dasoutfolder/maxbin.tsv

echo "$metabatoutfolder/final.contigs.fa.metabat-bins1500"

cd $metabatoutfolder/final.contigs.fa.metabat-bins1500
Fasta_to_Scaffolds2Bin.sh -e fa > $dasoutfolder/metabat.tsv

cd $concoctoutfolder/bin
Fasta_to_Scaffolds2Bin.sh -e fa > $dasoutfolder/concoct.tsv

DAS_Tool -i $dasoutfolder/maxbin.tsv,$dasoutfolder/metabat.tsv,$dasoutfolder/concoct.tsv -l maxbin,metabat,concoct -c $megahitout/final.contigs.fa -o $dasoutfolder/o -t 16 --search_engine diamond --write_bins

fi


o_bins=$dasoutfolder/o_DASTool_bins
cd $script_folder



 if [ ! -d $das_checkmfolder ];
 then

 checkm  lineage_wf -t 8 -x fa $o_bins $das_checkmfolder

 fi


DAS_coverage=$dasoutfolder"_coverage.txt"
 if [ ! -f $DAS_coverage ];
 then 
 find $o_bins  \( -name "*.fa" -o -name "*.fasta" \) -printf "\n\n%f\t" -exec python bam_coverage.py $bamoutfolder/mapping_sort.bam  {} 150 \; > $DAS_coverage
 fi



o_bins=$maxbinoutfolder
if [ ! -d $maxbin_checkmfolder ];
then
checkm  lineage_wf -t 8 -x fasta $o_bins $maxbin_checkmfolder

fi

maxbin_coverage=$maxbinoutfolder"_coverage.txt"
 if [ ! -f $maxbin_coverage ];
 then 
 find $o_bins  \( -name "*.fa" -o -name "*.fasta" \) -printf "\n\n%f\t" -exec python bam_coverage.py $bamoutfolder/mapping_sort.bam  {} 150 \; > $maxbin_coverage
 fi



o_bins=$metabatoutfolder/final.contigs.fa.metabat-bins1500
if [ ! -d $metabat_checkmfolder ];
then

checkm  lineage_wf -t 8 -x fa $o_bins $metabat_checkmfolder

fi

metabat_coverage=$metabatoutfolder"_coverage.txt"
 if [ ! -f $metabat_coverage ];
 then 
 find $o_bins  \( -name "*.fa" -o -name "*.fasta" \) -printf "\n\n%f\t" -exec python bam_coverage.py $bamoutfolder/mapping_sort.bam  {} 150 \; > $metabat_coverage
 fi


o_bins=$concoctoutfolder/bin
if [ ! -d $concoct_checkmfolder ];
then

checkm  lineage_wf -t 8 -x fa $o_bins $concoct_checkmfolder

fi

concoct_coverage=$concoctoutfolder"_coverage.txt"
 if [ ! -f $concoct_coverage ];
 then 
 find $o_bins  \( -name "*.fa" -o -name "*.fasta" \) -printf "\n\n%f\t" -exec python bam_coverage.py $bamoutfolder/mapping_sort.bam  {} 150 \; > $concoct_coverage
 fi

checkm_summary=$1/checkm_summary.txt
find $1 -maxdepth 1 -type d -name "*_checkm" -printf "\n%f\n" -exec python checkm_compilor_general.py {} \; > $checkm_summary