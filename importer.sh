#!/bin/bash

sicklepath="/home/sih13/tool/sickle-master/sickle"

R1=$(find $1 -maxdepth 1 -regex '\S+fastq'  -not -name "*trimmed*" | grep "R1" | head -n $SLURM_ARRAY_TASK_ID | tail -n 1)
#R1=$(find $1 -maxdepth 1 -regex '\S+fastq'  -not -name "*trimmed*" | grep "R1" | head -n 2 | tail -n 1)


R2=${R1/R1/"R2"}

R1trim=${R1/.fastq/"_trimmed.fastq"}
R2trim=${R2/.fastq/"_trimmed.fastq"}
single=${R1/.fastq/"_single_trimmed.fastq"}
single=${single/R1/""}

R1_no_carp=${R1/.fastq/"_trimmed_no_carp.fastq"}
R2_no_carp=${R2/.fastq/"_trimmed_no_carp.fastq"}

megahitout=${single/_single_trimmed.fastq/"_megahit"}

bamoutfolder=${single/_single_trimmed.fastq/"_bam"}

maxbinoutfolder=${single/_single_trimmed.fastq/"_maxbin"}

metabatoutfolder=${single/_single_trimmed.fastq/"_metabat"}
concoctoutfolder=${single/_single_trimmed.fastq/"_concoct"}
dasoutfolder=${single/_single_trimmed.fastq/"_das"}

das_checkmfolder=${single/_single_trimmed.fastq/"_das_checkm"}
maxbin_checkmfolder=${single/_single_trimmed.fastq/"_maxbin_checkm"}
metabat_checkmfolder=${single/_single_trimmed.fastq/"_metabat_checkm"}
concoct_checkmfolder=${single/_single_trimmed.fastq/"_concoct_checkm"}

maxbinout=$maxbinoutfolder"/maxbin"


 if [ ! -f $R1trim ];
 then
 $sicklepath pe -f $R1 -r $R2 -o $R1trim -p $R2trim -s $single --quiet -t sanger
 fi


 if [ ! -f $R1_no_carp ];
 then
 python filter_fasta_multiprocess.py './taboo.txt' $R1trim 8
 fi


 if [ ! -d $megahitout ];
 then
 megahit -1 $R1_no_carp -2 $R2_no_carp -o $megahitout -t 8
 fi


 if [ ! -d $maxbinoutfolder ];
 then
 mkdir $maxbinoutfolder

 run_MaxBin.pl -contig $megahitout/final.contigs.fa -out $maxbinout  -reads $R1_no_carp -reads2 $R2_no_carp -thread 8 -min_contig_length 200
 fi





 if [ ! -d $bamoutfolder ];
 then
 mkdir $bamoutfolder

 bowtie2-build $megahitout/final.contigs.fa $megahitout/final.contigs && bowtie2 -x $megahitout/final.contigs -1 $R1_no_carp  -2 $R2_no_carp  | samtools view -bS -o $bamoutfolder/mapping.bam

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


 if [ ! -d $das_checkmfolder ];
 then

 checkm  lineage_wf -t 8 -x fa $o_bins $das_checkmfolder

 fi

o_bins=$maxbinoutfolder
if [ ! -d $maxbin_checkmfolder ];
then


checkm  lineage_wf -t 8 -x fasta $o_bins $maxbin_checkmfolder
fi

o_bins=$metabatoutfolder/final.contigs.fa.metabat-bins1500
if [ ! -d $metabat_checkmfolder ];
then

checkm  lineage_wf -t 8 -x fa $o_bins $metabat_checkmfolder
fi

o_bins=$concoctoutfolder/bin
if [ ! -d $concoct_checkmfolder ];
then

checkm  lineage_wf -t 8 -x fa $o_bins $concoct_checkmfolder
fi



