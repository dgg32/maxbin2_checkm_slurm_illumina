#bam_venn
##find '/home/sih13/tmp/jorn_2020_1/2020_first_binning_4_no_carp/JP214_Nostoc_CCY40508_1x/JP214-Nostoc_CCY0508_DSM101304_S11__001_concoct/bin'  \( -name "*.fa" -o -name "*.fasta" \) -printf "\n\n%f" -exec python '/home/sih13/python/bam_coverage.py' '/home/sih13/tmp/jorn_2020_1/2020_first_binning_4_no_carp/JP214_Nostoc_CCY40508_1x/JP214-Nostoc_CCY0508_DSM101304_S11__001_bam/mapping_sort.bam'   {} \;

import sys
import pysam
import os
from multiprocessing import Pool, Lock
import multiprocessing
import screed
import functools

input_bam_file = sys.argv[1]
fasta_file = sys.argv[2]

contig_list = set()

lock = multiprocessing.Lock()

with screed.open(fasta_file) as seqfile:
    for read in seqfile:
        contig_list.add(read.name.split(" ")[0])

print (f"contig\treads\tlength")

def worker(contig):

    samfile_temp = pysam.AlignmentFile(input_bam_file, "rb")

    reads = samfile_temp.count(contig = contig, read_callback = "all")

    with lock:
        print (f"{contig}\t{reads}\t{samfile_temp.get_reference_length(contig)}")

    #return (shared, samfile_temp.get_reference_length(contig))

samfile = pysam.AlignmentFile(input_bam_file, "rb")

contigs = [x for x in samfile.references if x in contig_list]

#contigs = ["tig00000642"]

num_of_cpu = multiprocessing.cpu_count()

with Pool(num_of_cpu) as P:

    #P.map(worker, contigs)
    #pass
    P.map(worker, contigs)

    P.close()
    P.join()
    #print (f"shared: {results[0]}, reference_len: {results[1]}")

#print ("\n".join(str(x) for x in samfile.get_index_statistics()))

#print ("tig00000642" in contigs)