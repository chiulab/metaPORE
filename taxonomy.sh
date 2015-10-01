#!/bin/bash
#
#	taxonomy.sh
#
#	This program will query the NCBI taxonomic database and return whatever taxonomy is requested for a gi, or list of gis. The
#	returned data will be in tabular format, and will be in the following order.
#	Chiu Laboratory
#	University of California, San Francisco
#
# Copyright (C) 2015 Scot Federman - All Rights Reserved
# metaPORE has been released under a modified BSD license.
# Please see license file for details.

maxchunksize=8000
max_concurrent=12

gi_inputfile=$1
TAXONOMY_DB=$2

suffix=$(basename $gi_inputfile .gi)

if [[ ! $gi_inputfile ]]
then
	echo "You must supply an inputfile with gi"
	exit
fi

numgi=$(wc -l $gi_inputfile | awk '{print $1}')

min_split_size=$(( maxchunksize * max_concurrent ))

if (( $numgi < $min_split_size ))
then
	split -n l/$max_concurrent --additional-suffix "_$suffix" "$gi_inputfile"
else
	split -l $maxchunksize --additional-suffix "_$suffix" "$gi_inputfile"
fi

parallel --gnu -j $max_concurrent "taxonomy_lookup_standalone.pl -i {} -fgsxl -d nucl -q $TAXONOMY_DB > {}.taxonomy" ::: x??"_$suffix"

cat x??"_$suffix.taxonomy" > "$gi_inputfile.taxonomy"

rm x??"_$suffix"
rm x??"_$suffix.taxonomy"
