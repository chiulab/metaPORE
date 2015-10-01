#!/bin/bash
#
# 	picker.sh
#
#	Chiu Laboratory
#	University of California, San Francisco
#
# Copyright (C) 2015 Scot Federman - All Rights Reserved
# metaPORE has been released under a modified BSD license.
# Please see license file for details.

nt_DB="/reference/BLASTDB_01_27_2015/nt"

# if [[ $1 ]]
# then
# 	search_term=$1
# else
# 	search_term="Zaire"
# fi
# unified_file="../realtime_test1.unified"

optspec=":s:hu:"
bold=$(tput bold)
normal=$(tput sgr0)

scriptname=${0##*/}

while getopts "$optspec" option; do
	case "${option}" in
		s) search_term=${OPTARG};; 
		h) HELP=1;;
		u) unified_file=${OPTARG};; 
		:)	echo "Option -$OPTARG requires an argument." >&2
			exit 1
			;;
	esac
done

if [[ $HELP -eq 1  ||  $# -lt 1 ]]
then
	cat <<USAGE

${bold}${scriptname}${normal}

This program will pick a representative gi from a MetaPORE unified file.

${bold}Command Line Switches:${normal}

	-h	Show this help & ignore all other switches

	-s	Specify search term

	-u	Specify unified file

${bold}Usage:${normal}

	Pick representative gi for Zaire ebolavirus
		$scriptname -u realtime_test1.unified -s "Zaire ebolavirus"

USAGE
	exit
fi

#create correctly ordered list of gi (by frequency)
gi_list=$(grep "$search_term" "$unified_file" | awk '{print $4}' | sort | uniq -c | sort -rn | awk '{print $2}')

#then, look down list for:
#1. complete genome
#2. complete sequence
#3. partial sequence/individual gene
#4. top remaining sequence

gi_counter=0

for gi in $gi_list
do
	((gi_counter++))
	gi_type=$(blastdbcmd -db $nt_DB -entry $gi | head -1)
	if [[ "$gi_type" =~ "omplete genome" ]]
	then
		gi_to_pick=$gi
		break
	fi
# 	echo -e "$gi_counter\t$gi\t$gi_type"
done
	
if [[ ! $gi_to_pick ]]
then
	for gi in $gi_list
	do
		((gi_counter++))
		gi_type=$(blastdbcmd -db $nt_DB -entry $gi | head -1)
		if [[ "$gi_type" =~ "omplete sequence" ]]
		then
			gi_to_pick=$gi
			break
		fi
# 		echo -e "$gi_counter\t$gi\t$gi_type"
	done
fi

if [[ ! $gi_to_pick ]]
then
	for gi in $gi_list
	do
		((gi_counter++))
		gi_type=$(blastdbcmd -db $nt_DB -entry $gi | head -1)
		if [[ "$gi_type" =~ "partial sequence" ]]
		then
			gi_to_pick=$gi
			break
		fi
# 		echo -e "$gi_counter\t$gi\t$gi_type"
	done
fi

if [[ ! $gi_to_pick ]]
then
	for gi in $gi_list
	do
		((gi_counter++))
		gi_to_pick=$gi
		break
	done
fi

echo "$gi_to_pick"