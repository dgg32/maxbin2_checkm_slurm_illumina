##pair end fasta equalizer

import sys, re, csv, os

import gzip
import screed
import random

# from threading import Thread
# import queue

# in_queue = queue.Queue()
# out_queue = queue.Queue()



import time



R1_input_file = sys.argv[1]
R2_input_file = R1_input_file.replace("R1", "R2")

R1_output = R1_input_file.replace(".fastq", "_no_carp_10.fastq")
R2_output = R2_input_file.replace(".fastq", "_no_carp_10.fastq")


left_write_cache = ""
right_write_cache = ""
cache_count = 0

with open(R1_input_file) as left_seqfile, open(R2_input_file) as right_seqfile:

    left_read = ""
    right_read = ""

    pairs = []

    n = 0
    

    for left_line, right_line in zip(left_seqfile, right_seqfile):
        left_read += left_line
        right_read += right_line

        n += 1

        if n%4 == 0:
            choice = random.random() * 10
            

            if choice <= 1:

                left_write_cache += left_read
                right_write_cache += right_read
                cache_count += 1

                if cache_count >= 10:

                    with open(R1_output, 'a') as R1, open(R2_output, 'a') as R2:
                        R1.write(left_write_cache)

                        R2.write(right_write_cache)
                    
                    left_write_cache = ""
                    right_write_cache = ""
                    cache_count = 0


            left_read = ""
            right_read = ""


if len(left_write_cache) > 0 and len(right_write_cache) > 0:
    with open(R1_output, 'a') as R1, open(R2_output, 'a') as R2:
        R1.write(left_write_cache)

        R2.write(right_write_cache)

