#!/bin/bash
cat << EOF
---------------------------------------------------
                   ▓▓░  ▓▓▓  ░▓▓▓
  -. .-.   .-. .- ▓░ ▓░▓░   ░▓  ░▓ -. .-.   .-. .-
  ||\|||\ /|||\|| ▓▓▓▓░▓░░▓▓░▓     ||\|||\ /|||\||
  |/ \|||\|||/ \| ▓░ ▓░▓░ ░▓░▓  ░▓ |/ \|||\|||/ \|
  ¯   '-¯ '-'   ' ▓░ ▓░ ▓▓▓  ░▓▓▓  ¯   '-¯ '-'   '
 T H E  A P P L I E D  G E N O M I C S  C E N T R E
          --- Coding a better harvest ---
---------------------------------------------------
The  purpose of  this script is to  trim reads from
the NGS microbial in-house test
EOF
# ---------------------------------------------------
# SETTING UP DIRECTORIES TO BE USED
# ---------------------------------------------------
# *WHICH_RUN, IMPORT_FASTQS, and SAMPLE_SHEET need to be changed for each run
# *Change WHICH_RUN for each dataset that you're analyzing
# ---------------------------------------------------
WHICH_RUN=20240911-Norgen_Nano_16S_ITS # Including this to help remove human error, just changing this one variable will enable formatting this workflow for any datasets
FASTQS_LOC=Fastq # This will vary between "Basecalls" and "Alignment_1"
# *Change the subfolder for IMPORT_FASTQS depending on the dataset
# Root directories for the project
# ---------------------------------------------------
RAW_DATA=~/Documents/paddy/NGS_microbial_samples_testing/data/raw_data
FASTQS=${RAW_DATA}/$WHICH_RUN/$FASTQS_LOC
ANALYZED_DATA=~/Documents/paddy/NGS_microbial_samples_testing/data/analyzed_data
PRETRIM_FASTQC=${ANALYZED_DATA}/$WHICH_RUN/fastqc_pretrim
POSTTRIM_FASTQC=${ANALYZED_DATA}/$WHICH_RUN/fastqc_posttrim
TRIM_FASTQS=${RAW_DATA}/$WHICH_RUN/fastq_trimmed
TRIM_SURV_FASTQS=${RAW_DATA}/$WHICH_RUN/fastq_trimmed/surviv_pairs_fastqs
TRIM_ORPH_FASTQS=${RAW_DATA}/$WHICH_RUN/fastq_trimmed/orphan_pairs_fastqs
SAMPLE_LIST=${RAW_DATA}/$WHICH_RUN/sample_list.txt
ADAPTER_FASTA=${RAW_DATA}/$WHICH_RUN/adapters_for_trimming.fa
# Adapter sequences were pulled from both available ITS and 16S protocols from manufacturer
# Adapters were taken as the sequence from amplicon primers that matched,
# i.e., any different sequences then indicated targeting ITS or 16S region
TEMP_UNZIP_FOLDER=${ANALYZED_DATA}/$WHICH_RUN/temp_unzipped_fastqs
TRIM_FQ_FRAGMENT_COUNTS=${ANALYZED_DATA}/$WHICH_RUN/trimmed_fastq_fragment_counts.csv
## ---------------------------------------------------
## PRE-TRIM QC (.fastq FOR .html REPORT)
## ---------------------------------------------------
#[ ! -d ${PRETRIM_FASTQC} ] && mkdir -m 755 ${PRETRIM_FASTQC}
#fastqc -t 16 -o ${PRETRIM_FASTQC} ${FASTQS}/*.fastq.gz
#multiqc ${PRETRIM_FASTQC} --title $WHICH_RUN --filename $WHICH_RUN --outdir ${PRETRIM_FASTQC}
#[ -r ${PRETRIM_FASTQC}/"$WHICH_RUN".html ] && echo "QC has completed"
# ---------------------------------------------------
# PERFORM TRIMMING (.fastq ONLY, OUTPUT IS .fastq)
# ---------------------------------------------------
#[ ! -d ${TRIM_FASTQS} ] && mkdir -m 755 ${TRIM_FASTQS}
#[ ! -d ${TRIM_SURV_FASTQS} ] && mkdir -m 755 ${TRIM_SURV_FASTQS}
#[ ! -d ${TRIM_ORPH_FASTQS} ] && mkdir -m 755 ${TRIM_ORPH_FASTQS}
#ls ${FASTQS} | grep .fastq.gz | sed 's/_L001.*/_L001/' | sort | uniq > $SAMPLE_LIST
#while IFS= read -r SAMPLE_ID; do
#    trimmomatic \
#        PE \
#        -threads 16 \
#        -phred33 \
#        -trimlog ${TRIM_FASTQS}/20240717_trim.log \
#        ${FASTQS}/"$SAMPLE_ID"_R1_001.fastq.gz \
#        ${FASTQS}/"$SAMPLE_ID"_R2_001.fastq.gz \
#        ${TRIM_SURV_FASTQS}/trimmed-surviv-pairs-"$SAMPLE_ID"_R1_001.fastq.gz \
#        ${TRIM_ORPH_FASTQS}/trimmed-orphan-pairs-"$SAMPLE_ID"_R1_001.fastq.gz \
#        ${TRIM_SURV_FASTQS}/trimmed-surviv-pairs-"$SAMPLE_ID"_R2_001.fastq.gz \
#        ${TRIM_ORPH_FASTQS}/trimmed-orphan-pairs-"$SAMPLE_ID"_R2_001.fastq.gz \
#        ILLUMINACLIP:$ADAPTER_FASTA:2:30:10:2:True SLIDINGWINDOW:4:20 LEADING:3 TRAILING:3 MINLEN:36
#done < $SAMPLE_LIST
#if ls "${TRIM_SURV_FASTQS}"/*.fastq.gz 1>/dev/null 2>&1; then
#    echo "Adapter trimming has completed. Be sure to check that all your sample fastqs are accounted for"
#    exit 0
#else
#    echo "There was an issue with trimming fastqs. Check your files and your script before trying again"
#    exit 1
#fi
## ---------------------------------------------------
## UNZIP ALL THE TRIMMED FASTQS FOR THE DOWNSTREAM CHECK FOR PARITY
## ---------------------------------------------------
[ ! -d ${TEMP_UNZIP_FOLDER} ] && mkdir -m 755 ${TEMP_UNZIP_FOLDER}
for FILE in "${TRIM_SURV_FASTQS}"/*.gz; do
    BASENAME=$(basename "$FILE" .gz)
    gunzip -c "$FILE" > "${TEMP_UNZIP_FOLDER}/${BASENAME}"
done
## ---------------------------------------------------
## NOW CHECK FOR PARITY IN THE NUMBER OF FRAGMENT COUNTS FOR TRIMMED PAIRED-END FASTQS
## ---------------------------------------------------
#echo "Sample_fastq,R1_count,R2_count" > $TRIM_FQ_FRAGMENT_COUNTS
for FILE in "${TEMP_UNZIP_FOLDER}"/*R1*; do
    SAMPLE_NAME=$(basename "${FILE/_L001_R1_001.fastq}")
    R1_COUNTS=$(wc -l < "$FILE")
    echo "${SAMPLE_NAME},$((R1_COUNTS / 4))," >> $TRIM_FQ_FRAGMENT_COUNTS
done
for FILE in "${TEMP_UNZIP_FOLDER}"/*R2*; do
    SAMPLE_NAME=$(basename "${FILE/_L001_R2_001.fastq}")
    R2_COUNTS=$(wc -l < "$FILE")
    R2_READ_COUNTS=$((R2_COUNTS / 4))
    sed -i "/^${SAMPLE_NAME},/ s/,$/,${R2_READ_COUNTS}/" $TRIM_FQ_FRAGMENT_COUNTS
done
sed -i 's/trimmed-surviv-pairs-//' $TRIM_FQ_FRAGMENT_COUNTS
if $TRIM_FQ_FRAGMENT_COUNTS 1>/dev/null 2>&1; then
    echo "Check for read fragments parity completed"
    exit 0
else
    echo "There was an issue generating the read fragments counts. Check your files and your code before trying again"
    exit 1
fi
# ---------------------------------------------------
# PERFORM TRIMMED READS QC (.fastq FOR .html REPORT)
# ---------------------------------------------------
[ ! -d ${POSTTRIM_FASTQC} ] && mkdir -m 755 ${POSTTRIM_FASTQC}
fastqc -t 16 -o ${POSTTRIM_FASTQC} ${TRIM_SURV_FASTQS}/*.fastq.gz
multiqc ${POSTTRIM_FASTQC} --title $WHICH_RUN --filename $WHICH_RUN --outdir ${POSTTRIM_FASTQC}
[ -r ${POSTTRIM_FASTQC}/"$WHICH_RUN".html ] && echo "QC has completed"