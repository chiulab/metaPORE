#!/usr/bin/env python
#
#	metaporeRTServer_v2.py
#
#	Chiu Laboratory
#	University of California, San Francisco
#
# Copyright (C) 2015 Doug Stryke - All Rights Reserved
# metaPORE has been released under a modified BSD license.
# Please see license file for details.

"""
Ajax backend for Minion data.
"""

import json
import os
import sqlite3
if True:
	# tracebacks appear on browser
	import cgitb
	cgitb.enable()

dbPath_default = "/data1/sfederman/minion/hepc_6_9_2015/hepc_6_9_2015.db"

def family(dbPath=None):
	if dbPath is None:
		dbPath = dbPath_default
	_fetch('SELECT * from family', dbPath)

def genus(dbPath=None):
	if dbPath is None:
		dbPath = dbPath_default
	_fetch('SELECT * from genus', dbPath)

def species(dbPath=None):
	if dbPath is None:
		dbPath = dbPath_default
	_fetch('SELECT * from species', dbPath)
	
def virus_species(dbPath=None):
	if dbPath is None:
		dbPath = dbPath_default
	_fetch_virus('SELECT * from virus_species', dbPath)

def bacteria_species(dbPath=None):
	if dbPath is None:
		dbPath = dbPath_default
	_fetch_virus('SELECT * from bacteria_species', dbPath)

def all_reads(dbPath=None):
	if dbPath is None:
		dbPath = dbPath_default
	_fetch_all_reads('SELECT * from all_reads', dbPath)

def representative_sequence(dbPath=None):
	if dbPath is None:
		dbPath = dbPath_default
	_fetch('SELECT * from representative_sequence', dbPath)

def pipeline(dbPath=None):
	if dbPath is None:
		dbPath = dbPath_default
	_fetch('SELECT * from pipeline', dbPath)


def timestamp(dbPath=None):
	if dbPath is None:
		dbPath = dbPath_default
	conn = sqlite3.connect(dbPath)
	c = conn.cursor()
	print 'Content-Type: text/plain\n'
	print list(c.execute('SELECT last_update from Metadata'))[0][0]


def _fetch(select, dbPath):
	"""We want the following data structure
	 [
		{ y : 1, label: "Bos taurus"},
		{ y : 26 , label: "Chikungunya virus"},
		{ y : 1 , label: "Cloning vector TLF97-3"},
		{ y : 1 , label: "Cloning vector lambdaS2775"},
		{ y : 1 , label: "Macaca mulatta"},
		{ y : 1 , label: "Oryctolagus cuniculus"},
		{ y : 1 , label: "Pongo abelii"},
		{ y : 3 , label: "Enterobacteria phage HK630" },
		{ y : 2 , label: "Enterobacteria phage lambda" },
		{ y : 649 , label: "Homo sapiens" },
		{ y : 1 , label: "Oryctolagus cuniculus" },
		{ y : 15 , label: "Pan troglodytes" },
		{ y : 1 , label: "Sus scrofa" }
	 ]
	"""
	conn = sqlite3.connect(dbPath)
	c = conn.cursor()
	data = []
	for row in c.execute(select):
		# (u'Homo sapiens', 3784)
		formatted_counts = '{:,}'.format(row[1])
		label = row[0] + ' (' + formatted_counts + ')'
		data.append({'y': row[1], 'label': label})

	_printData(json.dumps(data))
	
def _fetch_virus(select, dbPath):
	conn = sqlite3.connect(dbPath)
	c = conn.cursor()
	data = []
	for row in c.execute(select):
		# (u'Homo sapiens', 3784)
		formatted_counts = '{:,}'.format(row[1])
		label = row[0] + ' (' + formatted_counts + ')'
		data.append({'y': row[1], 'label': label, 'legendText': label, 'indexLabelFontStyle': 'italic'})

	_printData(json.dumps(data))

def _fetch_all_reads(select, dbPath):
	conn = sqlite3.connect(dbPath)
	c = conn.cursor()
	data = []
	for row in c.execute(select):
		# (u'Homo sapiens', 3784, red)
		formatted_counts = '{:,}'.format(row[1])
		label = row[0] + ' (' + formatted_counts + ')'
		if row[0] == "Homo sapiens":
			data.append({'y': row[1], 'label': label, 'legendText': label, 'color' : row[2], 'indexLabelFontStyle': 'italic'})
		else:
			data.append({'y': row[1], 'label': label, 'legendText': label, 'color' : row[2], 'indexLabelFontStyle': 'normal'})

	_printData(json.dumps(data))

def _printData(data):
	print 'Content-Type: application/json\n'
	print data

def main():
	print 'Content-Type: text/plain\n'
	print 'Not a valid request.'

if __name__ == '__main__':
	# import only those modules used below
	import sys
	from cStringIO import StringIO
	if len(sys.argv) > 1:
		# Allows command line testing.
		func = eval(sys.argv[1])
		func(*sys.argv[2:])
	else:
		import cgi
		form = cgi.FieldStorage()
		d = {}
		for key in form.keys():
			try:
				d[key] = form[key].value
			except AttributeError:
				d[key] = form.getlist(key)
		action = d.pop("action", "main")

		func = eval(action)
		func(**d)
