#!/usr/bin/python
#
# 	populate_database.py
#
#	Chiu Laboratory
#	University of California, San Francisco
#
# Copyright (C) 2015 Scot Federman - All Rights Reserved
# metaPORE has been released under a modified BSD license.
# Please see license file for details.

import sqlite3
import sys
import os

usage = "populate_database.py <project> <batch>"

if len(sys.argv) != 3:
	print usage
	sys.exit(0)

project = sys.argv[1]
batch = sys.argv[2]

database = project + ".db"

conn = sqlite3.connect(database)
c = conn.cursor()

species_file = project + "_" + batch + ".human_subtracted.species.count"
genus_file   = project + "_" + batch + ".human_subtracted.genus.count"
family_file  = project + "_" + batch + ".human_subtracted.family.count"

human_species_file = project + "_" + batch + ".human.species.count"
human_genus_file   = project + "_" + batch + ".human.genus.count"
human_family_file  = project + "_" + batch + ".human.family.count"

pipeline_file = project + "_" + batch + ".count"
representative_reads_file = project + "_" + batch + ".rep.count"
all_reads_file = project + "_" + batch + ".all_reads.count"

virus_species = project + "_" + batch + ".human_subtracted.species.viruses.count"
bacteria_species = project + "_" + batch + ".human_subtracted.species.bacteria.count"

if os.path.isfile(virus_species):
	with open(virus_species, 'r') as map_file:
		for line in map_file:
			item = line.lstrip().split(" ", 1)
			species_name = item[1].strip()
			count = int(item[0])

			c.execute("SELECT count FROM virus_species WHERE name = ?", [species_name])
			existing_value = c.fetchall()

			if len(existing_value)==0:
				c.execute('INSERT INTO virus_species VALUES (?,?)', (species_name, count))
			else:
				newcount = count + int(existing_value[0][0])
				c.execute("update virus_species set count = ? where name = ?", (newcount, species_name))

if os.path.isfile(bacteria_species):
	with open(bacteria_species, 'r') as map_file:
		for line in map_file:
			item = line.lstrip().split(" ", 1)
			species_name = item[1].strip()
			count = int(item[0])

			c.execute("SELECT count FROM bacteria_species WHERE name = ?", [species_name])
			existing_value = c.fetchall()

			if len(existing_value)==0:
				c.execute('INSERT INTO bacteria_species VALUES (?,?)', (species_name, count))
			else:
				newcount = count + int(existing_value[0][0])
				c.execute("update bacteria_species set count = ? where name = ?", (newcount, species_name))

if os.path.isfile(pipeline_file):
	with open(pipeline_file, 'r') as map_file:
		for line in map_file:
			item = line.lstrip().split(" ", 1)
			name = item[1].strip()
			count = int(item[0])

			c.execute("SELECT count FROM pipeline WHERE name = ?", [name])
			existing_value = c.fetchall()

			if len(existing_value)==0:
				c.execute('INSERT INTO pipeline VALUES (?,?)', (name, count))
			else:
				newcount = count + int(existing_value[0][0])
				c.execute("update pipeline set count = ? where name = ?", (newcount, name))

if os.path.isfile(representative_reads_file):
	with open(representative_reads_file, 'r') as map_file:
		for line in map_file:
			item = line.lstrip().split(" ", 1)
			name = item[1].strip()
			count = int(item[0])

			c.execute("SELECT count FROM representative_sequence WHERE name = ?", [name])
			existing_value = c.fetchall()

			if len(existing_value)==0:
				c.execute('INSERT INTO representative_sequence VALUES (?,?)', (name, count))
			else:
				newcount = count + int(existing_value[0][0])
				c.execute("update representative_sequence set count = ? where name = ?", (newcount, name))

if os.path.isfile(all_reads_file):
	with open(all_reads_file, 'r') as map_file:
		for line in map_file:
			item = line.lstrip().split(" ", 1)
			name = item[1].strip()
			count = int(item[0])

			c.execute("SELECT count FROM all_reads WHERE name = ?", [name])
			existing_value = c.fetchall()
			c.execute("SELECT color FROM all_reads WHERE name = ?", [name])
			existing_color = c.fetchall()
			if len(existing_value)==0:
				c.execute('INSERT INTO all_reads VALUES (?,?,?)', (name, count, existing_color[0].strip()))
			else:
				newcount = count + int(existing_value[0][0])
				c.execute("update all_reads set count = ? where name = ?", (newcount, name))

if os.path.isfile(human_species_file):
	with open(human_species_file, 'r') as map_file:
		for line in map_file:
			item = line.lstrip().split(" ", 1)
			species_name = item[1].strip()
			count = int(item[0])

			c.execute("SELECT count FROM species WHERE name = ?", [species_name])
			existing_value = c.fetchall()

			if len(existing_value)==0:
				c.execute('INSERT INTO species VALUES (?,?)', (species_name, count))
			else:
				newcount = count + int(existing_value[0][0])
				c.execute("update species set count = ? where name = ?", (newcount, species_name))

if os.path.isfile(human_genus_file):
	with open(human_genus_file, 'r') as map_file:
		for line in map_file:
			item = line.lstrip().split(" ", 1)
			genus_name = item[1].strip()
			count = int(item[0])

			c.execute("SELECT count FROM genus WHERE name = ?", [genus_name])
			existing_value = c.fetchall()

			if len(existing_value)==0:
				c.execute('INSERT INTO genus VALUES (?,?)', (genus_name, count))
			else:
				newcount = count + int(existing_value[0][0])
				c.execute("update genus set count = ? where name = ?", (newcount, genus_name))

if os.path.isfile(human_family_file):
	with open(human_family_file, 'r') as map_file:
		for line in map_file:
			item = line.lstrip().split(" ", 1)
			family_name = item[1].strip()
			count = int(item[0])

			c.execute("SELECT count FROM family WHERE name = ?", [family_name])
			existing_value = c.fetchall()

			if len(existing_value)==0:
				c.execute('INSERT INTO family VALUES (?,?)', (family_name, count))
			else:
				newcount = count + int(existing_value[0][0])
				c.execute("update family set count = ? where name = ?", (newcount, family_name))

if os.path.isfile(species_file):
	with open(species_file, 'r') as map_file:
		for line in map_file:
			item = line.lstrip().split(" ", 1)
			species_name = item[1].strip()
			count = int(item[0])

			c.execute("SELECT count FROM species WHERE name = ?", [species_name])
			existing_value = c.fetchall()

			if len(existing_value)==0:
				c.execute('INSERT INTO species VALUES (?,?)', (species_name, count))
			else:
				newcount = count + int(existing_value[0][0])
				c.execute("update species set count = ? where name = ?", (newcount, species_name))

if os.path.isfile(genus_file):
	with open(genus_file, 'r') as map_file:
		for line in map_file:
			item = line.lstrip().split(" ", 1)
			genus_name = item[1].strip()
			count = int(item[0])

			c.execute("SELECT count FROM genus WHERE name = ?", [genus_name])
			existing_value = c.fetchall()

			if len(existing_value)==0:
				c.execute('INSERT INTO genus VALUES (?,?)', (genus_name, count))
			else:
				newcount = count + int(existing_value[0][0])
				c.execute("update genus set count = ? where name = ?", (newcount, genus_name))

if os.path.isfile(family_file):
	with open(family_file, 'r') as map_file:
		for line in map_file:
			item = line.lstrip().split(" ", 1)
			family_name = item[1].strip()
			count = int(item[0])

			c.execute("SELECT count FROM family WHERE name = ?", [family_name])
			existing_value = c.fetchall()

			if len(existing_value)==0:
				c.execute('INSERT INTO family VALUES (?,?)', (family_name, count))
			else:
				newcount = count + int(existing_value[0][0])
				c.execute("update family set count = ? where name = ?", (newcount, family_name))

# Update metadata table, last_update field (flags web page to reload to help throttle down browser)
c.execute("SELECT last_update FROM Metadata")
existing_value = c.fetchall()

if len(existing_value)==0:
	initial_value = 1
	c.execute('INSERT INTO Metadata VALUES (?)', (initial_value,))
else:
	new_stamp = int(existing_value[0][0]) + 1
	c.execute("update Metadata set last_update = ? ", (new_stamp,))

conn.commit()
conn.close()
