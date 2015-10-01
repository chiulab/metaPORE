#!/usr/bin/python
#
# 	create_metaPORE_db.py
#
#	Chiu Laboratory
#	University of California, San Francisco
#
# Copyright (C) 2015 Scot Federman - All Rights Reserved
# metaPORE has been released under a modified BSD license.
# Please see license file for details.

import sqlite3
import sys

usage = "create_db_realtime.py <database_name>"

if len(sys.argv) != 2:
	print usage
	sys.exit(0)

database = sys.argv[1]

#
## Create database
#
print "Creating database: %s " % (database)

conn = sqlite3.connect(database)
c = conn.cursor()

c.execute('''CREATE TABLE Metadata (
				last_update TEXT)''')

c.execute('''CREATE TABLE virus_species (
				name TEXT,
				count INTEGER)''')
				
c.execute('''CREATE TABLE bacteria_species (
				name TEXT,
				count INTEGER)''')

c.execute('''CREATE TABLE species (
				name TEXT,
				count INTEGER)''')

c.execute('''CREATE TABLE genus (
				name TEXT,
				count INTEGER)''')

c.execute('''CREATE TABLE family (
				name TEXT,
				count INTEGER)''')

c.execute('''CREATE TABLE representative_sequence (
				name TEXT,
				count INTEGER)''')
				
c.execute('''CREATE TABLE pipeline (
				name TEXT,
				count INTEGER)''')

c.execute('''CREATE TABLE all_reads (
				name TEXT,
				count INTEGER,
				color TEXT)''')

c.execute('INSERT INTO all_reads VALUES (?,?,?)', ("Homo sapiens",0,"tan"))
c.execute('INSERT INTO all_reads VALUES (?,?,?)', ("Unidentified reads",0,"Gray"))
c.execute('INSERT INTO all_reads VALUES (?,?,?)', ("Viruses",0,"Red"))
c.execute('INSERT INTO all_reads VALUES (?,?,?)', ("Cutadapt Removed",0,"Blue"))
c.execute('INSERT INTO all_reads VALUES (?,?,?)', ("Bacteria",0,"Green"))
c.execute('INSERT INTO all_reads VALUES (?,?,?)', ("non-Human Eukaryote",0,"Yellow"))
c.execute('INSERT INTO all_reads VALUES (?,?,?)', ("other lineage",0,"Black"))

c.execute('''CREATE TABLE sequences (
				name TEXT,
				channel INTEGER,
				file TEXT,
				exp_start_time INTEGER,
				start_time INTEGER,
				duration INTEGER,
				twoD_seq TEXT,
				twoD_qual TEXT,
				template_seq TEXT,
				template_qual TEXT,
				complement_seq TEXT,
				complement_qual TEXT)''')
				
c.execute('''CREATE TABLE BLAST (
				name TEXT,
				BLAST_hit_gi TEXT,
				e_value REAL,
				taxid INTEGER	)''')

conn.commit()
conn.close()
