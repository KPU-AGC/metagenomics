#!/bin/bash

#------------ I/O Variables -----------#
INPUT_DIR=$1
OUTPUT_DIR=$2

#------------ I/O Variables -----------#
NCORES=$3
FORWARD_PRIMER=$4
REVERSE_PRIMER=$5

qiime tools import \
    --type SampleData[PairedEndSequencesWithQuality] \
    --input-path $INPUT_DIR \
    --output-path $OUTPUT_DIR/reads.qza \
    --input-format CasavaOneEightSingleLanePerSampleDirFmt

qiime cutadapt trim-paired \
    --i-demultiplexed-sequences $OUTPUT_DIR/reads.qza \
    --p-anywhere-f $FORWARD_PRIMER \
    --p-anywhere-r $REVERSE_PRIMER \
    --p-discard-untrimmed \
    --p-no-indels \
    --p-cores $NCORES \
    --o-trimmed-sequences $OUTPUT_DIR/reads_trimmed.qza

qiime vsearch join-pairs \
    --i-demultiplexed-seqs $OUTPUT_DIR/reads_trimmed.qza \
    --o-joined-sequences $OUTPUT_DIR/reads_trimmed_joined.qza