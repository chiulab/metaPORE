#!/usr/bin/env python
#
# 	split_fasta_by_id.py
#
#	Chiu Laboratory
#	University of California, San Francisco
#
# Copyright (C) 2015 Scot Federman - All Rights Reserved
# metaPORE has been released under a modified BSD license.
# Please see license file for details.



#This program receives 6 arguments:

# 1 - Input file (in FASTA format)
# 2 - gi list
# 3 - Output filename (in FASTA format)
#	This file contains sequences not in the identifier list
# 4 - Output filename (in FASTA format)
#	This file contains sequences in the identifier list
# The next 2 values allow you to describe where you identifer is located within the FAST header:
# 5 - delimiter
#	This value describes the delimiter used in dividing the column within the header
# 6 - column
#	This value is 0 based, so column numbering starts at 0.
	
# e.g. If the header is in the following format:
# >gi|4|emb|X17276.1|
# The delimiter is |
# The identifer (the gi number) is in column 1 (remember this is 0 based)

import sys
from Bio import SeqIO

usage = "split_fasta_by_id.py <inputfile (FASTA)> <gi to remove> <output file (retained FASTA)> <output file (removed FASTA)> <delimiter> <column>"

if len(sys.argv) < 4:
	print usage
	sys.exit(0)


fasta_file = sys.argv[1]  # Input fasta file
gi_to_remove_file = sys.argv[2] # Input wanted file, one gene name per line
result_file = sys.argv[3] # Output fasta file
remove_file = sys.argv[4] # Output removed sequences FASTA file
delimiter = sys.argv[5]
column = sys.argv[6]

remove = set()
with open(gi_to_remove_file) as f:
	for line in f:
		line = line.strip()
		if line != "":
			remove.add(line)

fasta_sequences = SeqIO.parse(open(fasta_file),'fasta')

retained_sequences = 0
removed_sequences = 0

with open(result_file, "w") as f, open(remove_file, "w") as g:
	for fasta in fasta_sequences:
		name = fasta.id
		header = name.split(delimiter)
		if header[int(column)] not in remove and len(name) > 0:
			SeqIO.write([fasta], f, "fasta")
			retained_sequences +=1
		else:
			SeqIO.write([fasta], g, "fasta")
			removed_sequences +=1

# print "# sequences not in gi_to_remove_file: ", retained_sequences
# print "# sequences in gi_to_remove_file:", removed_sequences