import os, sys, re, json, pyphy

extension = "bin_stats_ext.tsv"



top_folder = sys.argv[1]

headers = ["marker lineage", "Completeness", "Contamination", "Mean contig length", "N50 (contigs)", "Coding density", "# contigs", "Genome size"]

container = []

print ("bin\t" + "\t".join(headers))

for (head, dirs, files) in os.walk(top_folder):
    for file in files:
        if file.endswith(extension):
            current_file_path = os.path.abspath(os.path.dirname(os.path.join(head, file)))
            with_name = current_file_path + "/"+ file

            for line in open(with_name, 'r'):
                #print (line)
                fields = line.strip().split("\t")

                if len(fields) > 0:

                    

                    content = json.loads(fields[1].replace("'", '"'))

                    for header in headers:
                        if isinstance(content[header], float):
                            content[header] = round(content[header], 2)

                    #print (content)

                    #print (json.dumps({"taxid": int(taxid), "content": content}))
                    #print (line)
                    #print (str(fields[0]) + "\t" + "\t".join([str(fields[0]), str(content["marker lineage"]), str(content["Completeness"]), str(content["Contamination"]), str(content["Mean contig length"]), str(content["N50 (contigs)"]), str(content["Coding density"]), str(content["# contigs"]), str(content["Genome size"])]))
                    print (str(fields[0]) + "\t" + "\t".join([str(content[x]) for x in headers]))
            print ("\n")

  