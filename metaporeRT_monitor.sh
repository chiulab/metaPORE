#!/bin/bash
#
#	metaporeRT_monitor.sh
#
#	Chiu Laboratory
#	University of California, San Francisco
#
# Copyright (C) 2015 Scot Federman - All Rights Reserved
# metaPORE has been released under a modified BSD license.
# Please see license file for details.

scriptname=${0##*/}

optspec=":f:hn:m:l:b:a:c:i:"
bold=$(tput bold)
normal=$(tput sgr0)

while getopts "$optspec" option; do
	case "${option}" in
		h) HELP=1;;
		a) alignment_method=${OPTARG};;
		i) identification_db=${OPTARG};;
		f) fast5_folder=${OPTARG};;		#folder containing FAST5 files to be processed
		n) project_name=${OPTARG};;		#project name
		m) mode=${OPTARG};;				#run mode (rt, reanalyze)
		b) batch_size=${OPTARG};;		#batch_size
		l) length=${OPTARG};;			#sequences will be chopped to this maximum length
		c) cores=${OPTARG};;
		:)	echo "Option -$OPTARG requires an argument." >&2
			exit 1
			;;
	esac
done

if [[ $HELP -eq 1  ||  $# -lt 1 ]]
then
	cat <<USAGE

${bold}${scriptname}${normal}

This program will run the metaPORE pipeline with the parameters supplied.

${bold}Command Line Switches:${normal}

	-h	Show this help & ignore all other switches

	-a	Specify alignment method to NT

		${bold}blastn${normal} (default)
			In this mode, BLASTn will be used as the aligner to NT.

		${bold}megablast${normal}
			In this mode, Megablast will be used as the aligner to NT.

			This method will run much faster than BLASTn, but may not be as sensitive.

	-i	Specify identification database

		${bold}NT${normal} (default)
			In this mode, the 2 step pipeline will be run:
				1. Host (human) subtraction
				2. NCBI NT identification

			This method will only identify sequences aligning to the viral fraction of NCBI NT.

		${bold}Viral${normal}
			In this mode, the 3 step pipeline will be run:
				1. Host (human) subtraction
				2. NCBI NT (Viral fraction) enrichment
				3. NCBI NT identification

			This method will only identify sequences aligning to the viral fraction of NCBI NT.

	-f	Specify FAST5 folder

		This switch is used to specify the folder containing FAST5 files to be processed.

	-n	Specify project name

		This switch is used to specify the project name.
		
	-m	Specify run mode
	
		${bold}rt${normal} (default)
			In this mode, the FAST5 folder will be monitored in realtime for files to flow into it.
			As files are created, they will be batched and analyzed by metaPORE.

		${bold}reanalyze${normal}
			In this mode, the existing contents of the FAST5 folder will be analyzed, but 
			will not be monitored. This is useful for reanalyzing data.
	
	-b	Specify batch size
	
		FAST5 files will be split into batches of this size entering the pipeline.

		Suggested batch sizes:
			rt: 200
			reanalyze: 500
	
	-l	Specify maximum length of sequence.
	
		Sequences will be restricted to this length. When using this option, preprocessing will be skipped.

	-c	Cores to use per batch
	
${bold}Usage:${normal}

	Run pipeline.
		$scriptname


USAGE
	exit
fi

create_metaPORE_db.py "$project_name.db"

# creation of a batch can be done in 2 ways (in rt mode).
# 1. either $batch_size FAST5 files show up in $fast5_folder, or
# 2. FAST5 files are awaiting the pipeline, and the last batch was > $batch_cutoff_time seconds ago
# the cutoff time is necessary to analyze the last group of sequences that may be smaller than the $batch_size

if [[ $mode == "rt" ]]
then
	batch_cutoff_time=120

	total_files=0
	new_files=0
	last_batch_time=$(date +%s)

	echo -e "$(date)\t$scriptname\tStarting realtime pipeline."
	inotifywait -m -r "$fast5_folder" -e close_write -e moved_to --exclude ".*\.log" |
		while read path action file; do
			((total_files++))
			((new_files++))
			filelist=("${filelist[@]}" "$path/$file")
			current_time=$(date +%s)
			time_since_last_batch=$(( current_time - last_batch_time ))
			if (( $new_files >= $batch_size || $time_since_last_batch > $batch_cutoff_time ))
			then
				((batch_num++))
				last_batch_time=$(date +%s)
				echo -e "$(date)\t$scriptname\tTRIGGER (at $new_files)"
				echo -e "$(date)\t$scriptname\tbatch: $batch_num, size: ${#filelist[@]}"
				if [[ $identification_db == "viral" ]]
				then
					metaporeRT_viral.sh -n "$project_name" -b "$batch_num" -m "$mode" -c "$cores" ${filelist[@]} &
				else
					metaporeRT.sh -n "$project_name" -b "$batch_num" -m "$mode" -c "$cores" -a "$alignment_method" ${filelist[@]} &
				fi
				unset filelist
				new_files=0
			fi
		done
elif [[ $mode == "reanalyze" ]]
then
	simultaneous_batches=16
	
	echo -e "$(date)\t$scriptname\tStarting reanalysis pipeline."

	if [[ $identification_db == "viral" ]]
	then
		echo -e "$(date)\t$scriptname\tid to Viral database."
		find "$fast5_folder" -type f -name "*.fast5" | parallel --gnu -j "$simultaneous_batches" -N "$batch_size" "metaporeRT_viral.sh -a $alignment_method -n $project_name -b {#} -m $mode -c $cores {}"
	else
		echo -e "$(date)\t$scriptname\tid to NT database."
		find "$fast5_folder" -type f -name "*.fast5" | parallel --gnu -j "$simultaneous_batches" -N "$batch_size" "metaporeRT.sh -a $alignment_method -n $project_name -b {#} -m $mode -c $cores {}"
	fi
fi
echo -e "$(date)\t$scriptname\tCompleted pipeline."

# elif [[ $length ]]
# 	then
# 		echo -e "$(date)\t$scriptname\tTrimming to maximum length of $length."
# # 		find "$fast5_folder" -type f -name "*.fast5" | parallel --gnu -j "$simultaneous_batches" -N "$batch_size" metaporeRT_length_exclusion.sh "$project_name" "{#}" "$mode" "$length" "{}"
# 		find "$fast5_folder" -type f -name "*.fast5" | parallel --gnu -j "$simultaneous_batches" -N "$batch_size" metaporeRT.sh -n "$project_name" -b "{#}" -m "$mode" -c "$cores" -l "$length" -f "{}"
# 	else
# # 		find "$fast5_folder" -type f -name "*.fast5" | parallel --gnu -j "$simultaneous_batches" -N "$batch_size" metaporeRT.sh "$project_name" "{#}" "$mode" "{}"
# 		find "$fast5_folder" -type f -name "*.fast5" | parallel --gnu -j "$simultaneous_batches" -N "$batch_size" metaporeRT.sh -n "$project_name" -b "{#}" -m "$mode" -c "$cores" -f "{}"
# 	fi
# fi