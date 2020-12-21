##pair end fasta equalizer

import sys, re, csv, os
from Bio.Seq import Seq

import gzip
import screed
import multiprocessing


# from threading import Thread
# import queue

# in_queue = queue.Queue()
# out_queue = queue.Queue()

in_queue = multiprocessing.Manager().Queue()
out_queue = multiprocessing.Manager().Queue()

import time

taboo_file = sys.argv[1]


R1_input_file = sys.argv[2]
R2_input_file = R1_input_file.replace("R1", "R2")

cores = 8

if len(sys.argv) >= 3:
    cores = int(sys.argv[3]) 

taboos = []
for line in open(taboo_file):
    line = line.strip()

    if len(line) > 0:
        taboos.append(line)

        taboo = Seq(line)
        rc_taboo = taboo.reverse_complement()

        taboos.append(str(rc_taboo))

def work():
    while True:

        pairs = in_queue.get()

        left_pair_content = ""
        right_pair_content = ""

        for pair in pairs:
            left_read = pair[0]
            right_read = pair[1]

            left_name = left_read.split("\n")[0]
            left_sequence = left_read.split("\n")[1]
            left_qual = left_read.split("\n")[3]

            right_name = right_read.split("\n")[0]
            right_sequence = right_read.split("\n")[1]
            right_qual = right_read.split("\n")[3]


            found = False
            for taboo in taboos:
                if taboo in left_sequence or taboo in right_sequence:
                    found = True
                    break

            if found == False:
                left_pair_content += f"{left_name}\n{left_sequence}\n+\n{left_qual}\n"
                right_pair_content += f"{right_name}\n{right_sequence}\n+\n{right_qual}\n"


        #print (left_pair_content)
        if left_pair_content != "" and right_pair_content != "":
            out_queue.put([left_pair_content, right_pair_content])
    
        in_queue.task_done()



for i in range(cores):
    t = multiprocessing.Process(target=work)
    t.daemon = True
    t.start()

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

            pairs.append([left_read, right_read])
            
            left_read = ""
            right_read = ""

            if len(pairs) == 100:
                in_queue.put(pairs)

                pairs = []


    in_queue.put(pairs)
            #print (left_read.name, right_read.name)
            
R1_output = R1_input_file.replace(".fastq", "_no_carp.fastq")
R2_output = R2_input_file.replace(".fastq", "_no_carp.fastq")





while not out_queue.empty():

    result = out_queue.get()


    left_pair_content = result[0]
    right_pair_content = result[1]

    with open(R1_output, 'a') as R1, open(R2_output, 'a') as R2:
        R1.write(left_pair_content)

        R2.write(right_pair_content)


    out_queue.task_done()


in_queue.join()
out_queue.join()
