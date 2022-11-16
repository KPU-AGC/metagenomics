#!/bin/bash

#------------ I/O Variables -----------#
INPUT_DIR=$1
OUTPUT_DIR=$2
NCORES=$3

time qiime deblur denoise-16S \
    --i-demultiplexed-seqs $OUTPUT_DIR/reads_trimmed_joined_filt.qza \
    --p-trim-length 270 \
    --p-sample-stats \
    --p-min-reads 1 \
    --p-jobs-to-start $NCORES \
    --output-dir $OUTPUT_DIR/deblur-output \
    --verbose