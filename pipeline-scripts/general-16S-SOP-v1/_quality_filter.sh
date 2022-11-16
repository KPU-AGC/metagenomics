#!/bin/bash

#------------ I/O Variables -----------#
INPUT_DIR=$1
OUTPUT_DIR=$2

#------------ I/O Variables -----------#
time qiime quality-filter q-score \
    --i-demux $OUTPUT_DIR/reads_trimmed_joined.qza \
    --o-filter-stats $OUTPUT_DIR/filt_stats.qza \
    --o-filtered-sequences $OUTPUT_DIR/reads_trimmed_joined_filt.qza \
    --verbose