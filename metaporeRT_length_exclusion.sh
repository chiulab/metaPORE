#!/bin/bash
#
# 	metaporeRT_length_exclusion.sh
#
#	Chiu Laboratory
#	University of California, San Francisco
#
# Copyright (C) 2015 Scot Federman - All Rights Reserved
# metaPORE has been released under a modified BSD license.
# Please see license file for details.

# metapore_pipeline
#
# input: fast5 files
# output: taxonomy tables of reads in fast5 files
#
# 1. extract sequence & other metadata from FAST5
# 2. preprocess to remove adapters
# 3. convert to fasta
# 4. BLASTN to human
#       if hit -> call human
#       else -> continue in pipeline
# 5. BLASTN to NT
# 6. reduce to 1 HSP
# 7. get taxonomy
# 8. compile family/genus/species table

scriptname=${0##*/}

#
## Set parameters
#
project=$1
batch_num=$2
mode=$3
length=$4

#Pull parameters out of options, remaining arguments are files_to_process
#So, number of shifts below should equal number of arguments above.
shift
shift
shift
shift
files_to_process="$@"

base="${project}_${batch_num}"


#This script is called after a batch number of FAST5 files has shown up to be processed. Sometimes these files
# have not completed being written, so wait 20 seconds to start processing them.
# Added $mode option in order to only use this when in realtime mode.
if [[ "$mode" == "rt" ]]
then
	sleep 20
fi
PIPELINE_START=$(date +%s)
echo -e "$(date)\t$scriptname\tBatch: $batch_num - Starting sequence extraction..." >> "$base.log"

#
##
### FAST5 format - location of relevant items
##
#

location_channel="/Analyses/Basecall_2D_000/Configuration/general/channel"
location_file="/Analyses/Basecall_2D_000/Configuration/general/file_number"

location_exp_start="/UniqueGlobalKey/tracking_id/exp_start_time"
location_start="/Analyses/Basecall_2D_000/BaseCalled_template/Events/start_time"
location_duration="/Analyses/Basecall_2D_000/BaseCalled_template/Events/duration"

location_2D="/Analyses/Basecall_2D_000/BaseCalled_2D/Fastq"
location_complement="/Analyses/Basecall_2D_000/BaseCalled_complement/Fastq"
location_template="/Analyses/Basecall_2D_000/BaseCalled_template/Fastq"

#
##
### Extract data from .fast5 files
##
#
twoD_reads=0
complement_reads=0
template_reads=0
no_reads=0
files=0

for filename in $files_to_process
do
	((files++))

	header=$(basename $filename .fast5)
	channel=$(h5dump -a "$location_channel" "$filename" | grep "(0)" | awk '{print $2}' | sed 's/"//g')
	file_number=$(h5dump -a "$location_file" "$filename" | grep "(0)" | awk '{print $2}' | sed 's/"//g')

	exp_start_time=$(h5dump -a "$location_exp_start" "$filename" | grep "(0)" | awk '{print $2}' | sed 's/"//g')
	start_time=$(h5dump -a "$location_start" "$filename" | grep "(0)" | awk '{print $2}' | sed 's/"//g')
	duration=$(h5dump -a "$location_duration" "$filename" | grep "(0)" | awk '{print $2}' | sed 's/"//g')

	twoD=$(h5dump -d "$location_2D" 				-y "$filename" | grep "DATA " -A4 | tail -4 | sed 's/^ *//' | sed '1s/^"//')
	complement=$(h5dump -d "$location_complement"	-y "$filename" | grep "DATA " -A4 | tail -4 | sed 's/^ *//' | sed '1s/^"//')
	template=$(h5dump -d "$location_template"		-y "$filename" | grep "DATA " -A4 | tail -4 | sed 's/^ *//' | sed '1s/^"//')

	twoD_array=($twoD)
	complement_array=($complement)
	template_array=($template)
	file=$(basename $filename)

	if [[ ${twoD_array[0]} ]]
	then
		echo -e "$(date)\t$scriptname\tBatch: ${batch_num} File: $files: -> 2D" >> "$base.log"
		((twoD_reads++))
		echo "@${twoD_array[1]}_2d" >> "$base.fastq"
		echo "${twoD_array[2]}" >> "$base.fastq"
		echo "${twoD_array[3]}" >> "$base.fastq"
		echo "${twoD_array[4]}" >> "$base.fastq"
	else
		# decide whether to add complement or template
		if [[ ${complement_array[0]} && ! ${template_array[0]} ]]
		then
			echo -e "$(date)\t$scriptname\tBatch: ${batch_num} File: $files: -> Complement" >> "$base.log"
			((complement_reads++))
			echo "@${complement_array[1]}_complement" >> "$base.fastq"
			echo "${complement_array[2]}" >> "$base.fastq"
			echo "${complement_array[3]}" >> "$base.fastq"
			echo "${complement_array[4]}" >> "$base.fastq"
		elif [[ ${template_array[0]} && ! ${complement_array[0]} ]]
		then
			echo -e "$(date)\t$scriptname\tBatch: ${batch_num} File: $files: -> Template" >> "$base.log"
			((template_reads++))
			echo "@${template_array[1]}_template" >> "$base.fastq"
			echo "${template_array[2]}" >> "$base.fastq"
			echo "${template_array[3]}" >> "$base.fastq"
			echo "${template_array[4]}" >> "$base.fastq"
		elif [[ ! ${template_array[0]} && ! ${complement_array[0]} ]]
		then
			echo -e "$(date)\t$scriptname\tBatch: ${batch_num} File: $files: No reads exist." >> "$base.log"
			((no_reads++))
		else
			#both complement and template exist, so pick one with better quality
			echo "@${complement_array[1]}_complement" > "complement_$base.fastq"
			echo "${complement_array[2]}" >> "complement_$base.fastq"
			echo "${complement_array[3]}" >> "complement_$base.fastq"
			echo "${complement_array[4]}" >> "complement_$base.fastq"

			echo "@${template_array[1]}_template" > "template_$base.fastq"
			echo "${template_array[2]}" >> "template_$base.fastq"
			echo "${template_array[3]}" >> "template_$base.fastq"
			echo "${template_array[4]}" >> "template_$base.fastq"

			complement_qual=$(bioawk -c fastx '{ print meanqual($qual) }' "complement_$base.fastq")
			template_qual=$(bioawk -c fastx '{ print meanqual($qual) }' "template_$base.fastq")

			if (( $(bc <<< "$complement_qual > $template_qual") == 1 ))
			then
				echo -e "$(date)\t$scriptname\tBatch: ${batch_num} File: $files: Complement quality: $complement_qual, Template quality: $template_qual -> Complement" >> "$base.log"
				((complement_reads++))
				cat "complement_$base.fastq" >> "$base.fastq"
			else
				echo -e "$(date)\t$scriptname\tBatch: ${batch_num} File: $files: Complement quality: $complement_qual, Template quality: $template_qual -> Template" >> "$base.log"
				((template_reads++))
				cat "template_$base.fastq" >> "$base.fastq"
			fi
			rm "complement_$base.fastq"
			rm "template_$base.fastq"
		fi
# 		if (( $files%100 == 0 ))
# 		then
# 			echo -e "$(date)\t$scriptname\t$files processed..." >> "$base.log"
# 		fi
	fi
done
echo -e "$(date)\t$scriptname\tBatch: ${batch_num} 2D total: $twoD_reads" >> "$base.log"
echo -e "$(date)\t$scriptname\tBatch: ${batch_num} Complement total: $complement_reads" >> "$base.log"
echo -e "$(date)\t$scriptname\tBatch: ${batch_num} Template total: $template_reads" >> "$base.log"
echo -e "$(date)\t$scriptname\tBatch: ${batch_num} No reads total: $no_reads" >> "$base.log"
echo -e "$(date)\t$scriptname\tBatch: ${batch_num} - Completed sequence extraction." >> "$base.log"

#
##
### Convert to FASTA
##
#
echo -e "$(date)\t$scriptname\tBatch: ${batch_num} - Converting FASTQ to FASTA." >> "$base.log"
paste - - - - < "$base.fastq" | sed 's/^@/>/g'| cut -f1-2 | tr '\t' '\n' > "${base}_raw.fasta"

#
##
### Execute FASTA length exclusion
##
#
echo -e "$(date)\t$scriptname\tBatch: ${batch_num} - Running length exclusion (max length=$length)." >> "$base.log"
FASTA_length_exclusion.pl -s "$length" -i "${base}_raw.fasta" > "$base.fasta"

#
##
### BLAST to human
##
#
if [[ -e "$base.human.blastn" ]]
then
	echo -e "$(date)\t$scriptname\tUsing existing BLASTN to human: $base.human.blastn." >> "$base.log"
else
	e_value="1e-5"
	max_target_seqs=1
	format=6
	format_string="qseqid sseqid evalue"
	cores=16
	BLAST_DB="/home/sfederman/db/BLASTDB/Homo_sapiens_nt"
	#BLAST_DB="/home/sfederman/db/BLASTDB/GRCh38"

	echo -e "$(date)\t$scriptname\tBatch: ${batch_num} - Starting BLAST to human..." >> "$base.log"
	blastn -db "$BLAST_DB" \
			-query "$base.fasta" \
			-out "$base.human.blastn" \
			-max_target_seqs "$max_target_seqs" \
			-num_threads "$cores" \
			-evalue "$e_value" \
			-outfmt "$format $format_string" \
			-task blastn

	echo -e "$(date)\t$scriptname\tBatch: ${batch_num} - Completed BLAST to human." >> "$base.log"
fi

#
##
### Remove hits from secondary BLAST
##
#

#eventually remove the awk by only outputting the header in BLAST like this:
#format_string="qseqid"
if [[ -e "$base.human_hits.headers" ]]
then
	echo -e "$(date)\t$scriptname\tUsing existing headers: $base.human_hits.headers." >> "$base.log"
else
	awk '{print $1}' "$base.human.blastn"  > "$base.human_hits.headers"
fi

if [[ -e "$base.human_subtracted.fasta" ]]
then
	echo -e "$(date)\t$scriptname\tUsing existing human subtracted fasta: $base.human_subtracted.fasta." >> "$base.log"
else
	split_fasta_by_id.py "$base.fasta" "$base.human_hits.headers" "$base.human_subtracted.fasta" "$base.human.fasta" " " 0
fi

#
##
### BLAST to nt
##
#
e_value="1e-5"
max_target_seqs=1
format=6
format_string="qseqid sseqid evalue"
# 	max_hsps=1
cores=16
BLAST_DB="/reference/BLASTDB_01_27_2015/nt"

echo -e "$(date)\t$scriptname\tBatch: ${batch_num} - Starting BLAST..." >> "$base.log"
blastn -db "$BLAST_DB" \
	-query "$base.human_subtracted.fasta" \
	-out "$base.human_subtracted.blastn" \
	-max_target_seqs "$max_target_seqs" \
	-num_threads "$cores" \
	-evalue "$e_value" \
	-outfmt "$format $format_string" \
	-task blastn

echo -e "$(date)\t$scriptname\tBatch: ${batch_num} - Completed BLAST." >> "$base.log"

#
##
### reduce to 1HSP (may not be necessary with -max_hsps option)
##
#
echo -e "$(date)\t$scriptname\tBatch: ${batch_num} - Reducing to single HSP..." >> "$base.log"
awk '!x[$1]++' "$base.human_subtracted.blastn" > "$base.human_subtracted.blastn.1hsp"

echo -e "$(date)\t$scriptname\tBatch: ${batch_num} - Extracting gi..." >> "$base.log"
awk -F\| '{print $2}' "$base.human_subtracted.blastn.1hsp" > "$base.human_subtracted.blastn.1hsp.gi"

#
##
### Look up taxonomy for each gi
##
#
TAXONOMY_DB="/data1/reference/taxonomy/taxonomy_01222015/"
echo -e "$(date)\t$scriptname\tBatch: ${batch_num} - Starting taxonomy lookup..." >> "$base.log"
taxonomy.sh "$base.human_subtracted.blastn.1hsp.gi" "$TAXONOMY_DB"
echo -e "$(date)\t$scriptname\tBatch: ${batch_num} - Completed taxonomy lookup." >> "$base.log"

#
##
### Create table for each taxonomic unit
##
#
echo -e "$(date)\t$scriptname\tBatch: ${batch_num} - Creating taxonomy tables..." >> "$base.log"


total_reads=$(grep -c "^@Nanopore" "$base.fastq")

if [[ -e "$base.cutadapt.fastq" ]]
then
	cutadapt_reads=$(grep -c "^@Nanopore" "$base.cutadapt.fastq")
	cutadapt_fails=$(($total_reads - $cutadapt_reads))
else
	cutadapt_reads=$total_reads
	cutadapt_fails=0
fi

human_readcount=$(grep -c "^>" "$base.human.fasta")

#This method doesn't always work, since not all tax units are present, so cannot count on the column
# bacteria_reads=$(awk -F $'\t' '{print $6}' "$base.human_subtracted.blastn.1hsp.gi.taxonomy" | grep -c "Bacteria")
# virus_reads=$(awk -F $'\t' '{print $6}' "$base.human_subtracted.blastn.1hsp.gi.taxonomy" | grep -c "Virus")
# nhEUK_reads=$(awk -F $'\t' '{print $6}' "$base.human_subtracted.blastn.1hsp.gi.taxonomy" | grep -c "Eukaryota" | grep -v "Homo sapiens")
bacteria_reads=$(grep -c "Bacteria" "$base.human_subtracted.blastn.1hsp.gi.taxonomy")
virus_reads=$(grep -c "Virus" "$base.human_subtracted.blastn.1hsp.gi.taxonomy")
nhEUK_reads=$(grep -c "Eukaryota" "$base.human_subtracted.blastn.1hsp.gi.taxonomy" | grep -v "Homo sapiens")

total_blast_hits=$(wc -l "$base.human_subtracted.blastn.1hsp" | awk '{print $1}')
non_human_hits=$(( $total_reads - $human_readcount ))
other_reads=$(( $total_blast_hits - ($bacteria_reads + $virus_reads + $nhEUK_reads) ))
unidentified_reads=$(( $non_human_hits - $total_blast_hits ))

#Export category counts
echo -e "$total_reads Total reads" 				> "$base.count"
echo -e "$cutadapt_reads Cutadapt reads" 		>> "$base.count"
echo -e "$cutadapt_fails Cutadapt fails" 		>> "$base.count"
echo -e "$human_readcount Human"			 	>> "$base.count"

echo -e "$twoD_reads 2D reads" 					>> "$base.rep.count"
echo -e "$complement_reads complement reads" 	>> "$base.rep.count"
echo -e "$template_reads template reads" 		>> "$base.rep.count"
echo -e "$no_reads No reads" 					>> "$base.rep.count"

#Export human counts
echo -e "$human_readcount Hominidae" 		> "$base.human.family.count"
echo -e "$human_readcount Homo" 			> "$base.human.genus.count"
echo -e "$human_readcount Homo sapiens" 	> "$base.human.species.count"

#Export taxonomic counts
awk -F $'\t' '{print $5}' "$base.human_subtracted.blastn.1hsp.gi.taxonomy" | sed s/family--// | sort | uniq -c | sort -rn > "$base.human_subtracted.family.count"
awk -F $'\t' '{print $4}' "$base.human_subtracted.blastn.1hsp.gi.taxonomy" | sed s/genus--// | sort | uniq -c | sort -rn > "$base.human_subtracted.genus.count"
awk -F $'\t' '{print $3}' "$base.human_subtracted.blastn.1hsp.gi.taxonomy" | sed s/species--// | sort | uniq -c | sort -rn > "$base.human_subtracted.species.count"
awk -F $'\t' '{print $2}' "$base.human_subtracted.blastn.1hsp.gi.taxonomy" | sort | uniq -c | sort -rn > "$base.human_subtracted.taxid.count"
echo -e "$(date)\t$scriptname\tBatch: ${batch_num} - Completed taxonomy tables." >> "$base.log"

#Export all reads counts
echo -e "$human_readcount Homo sapiens" 			> "$base.all_reads.count"	#done/tested
echo -e "$unidentified_reads Unidentified reads"	>> "$base.all_reads.count"
echo -e "$virus_reads Viruses" 						>> "$base.all_reads.count"	#done
echo -e "$cutadapt_fails Cutadapt Removed"			>> "$base.all_reads.count"	#done/tested
echo -e "$bacteria_reads Bacteria" 					>> "$base.all_reads.count"	#done/tested
echo -e "$nhEUK_reads non-Human Eukaryote" 			>> "$base.all_reads.count"	#done/tested
echo -e "$other_reads other lineage"	 			>> "$base.all_reads.count"

#Export virus/bacteria species counts
grep "Viruses;" "$base.human_subtracted.blastn.1hsp.gi.taxonomy" >  "$base.human_subtracted.blastn.1hsp.gi.viruses.taxonomy"
grep "Bacteria;" "$base.human_subtracted.blastn.1hsp.gi.taxonomy" > "$base.human_subtracted.blastn.1hsp.gi.bacteria.taxonomy"

awk -F $'\t' '{print $3}' "$base.human_subtracted.blastn.1hsp.gi.viruses.taxonomy" | sed s/species--// | sort | uniq -c | sort -rn > "$base.human_subtracted.species.viruses.count"
awk -F $'\t' '{print $3}' "$base.human_subtracted.blastn.1hsp.gi.bacteria.taxonomy" | sed s/species--// | sort | uniq -c | sort -rn > "$base.human_subtracted.species.bacteria.count"

#
##
### Create unified file for downstream analysis
##
#
echo -e "$(date)\t$scriptname\tBatch: ${batch_num} - Creating unified file..." >> "$base.log"
paste "$base.human_subtracted.blastn.1hsp" "$base.human_subtracted.blastn.1hsp.gi.taxonomy" > "$base.unified"
echo -e "$(date)\t$scriptname\tBatch: ${batch_num} - Completed unified file." >> "$base.log"

#
##
### Now, push data into database.
##
#
echo -e "$(date)\t$scriptname\tBatch: ${batch_num} - Updating database..." >> "$base.log"
populate_database.py "$project" "$batch_num" 2> "$base.err"
PIPELINE_END=$(date +%s)
PIPELINE_TIME=$(( PIPELINE_END - PIPELINE_START ))

echo -e "$(date)\t$scriptname\tBatch: ${batch_num} - Pipeline completed in $PIPELINE_TIME seconds." >> "$base.log"
