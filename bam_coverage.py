#bam_venn

import sys
import pysam
import os
from multiprocessing import Pool, Lock
import multiprocessing
import screed
import functools

input_bam_file = sys.argv[1]
fasta_file = sys.argv[2]
read_length = int(sys.argv[3])

contig_list = set()

lock = multiprocessing.Lock()

length = 0

with screed.open(fasta_file) as seqfile:
    for read in seqfile:
        length += len(read.sequence)
        contig_list.add(read.name.split(" ")[0])

#print (f"contig\treads\tlength")

def worker(contig):

    samfile_temp = pysam.AlignmentFile(input_bam_file, "rb")

    reads = samfile_temp.count(contig = contig, read_callback = "all")

    return (reads)
    #with lock:
    #    print (f"{contig}\t{reads}\t{samfile_temp.get_reference_length(contig)}")

    #return (shared, samfile_temp.get_reference_length(contig))

samfile = pysam.AlignmentFile(input_bam_file, "rb")

contigs = [x for x in samfile.references if x in contig_list]

#contigs = ["tig00000642"]

num_of_cpu = multiprocessing.cpu_count()

with Pool(num_of_cpu) as P:

    #P.map(worker, contigs)
    #pass
    results = P.map(worker, contigs)

    P.close()
    P.join()

    print (sum(results) * read_length / length) 
    #print (f"shared: {results[0]}, reference_len: {results[1]}")

#print ("\n".join(str(x) for x in samfile.get_index_statistics()))

#print ("tig00000642" in contigs)