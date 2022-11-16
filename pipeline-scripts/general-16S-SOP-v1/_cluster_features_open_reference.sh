#!/bin/bash

#------------ I/O Variables -----------#
INPUT_DIR=$1
OUTPUT_DIR=$2
REFERENCE_SEQUENCES=$3

#------------ I/O Variables -----------#
time qiime vsearch cluster-features-open-reference \
    --i-sequences $OUTPUT_DIR/deblur-output/representative_sequences.qza \
    --i-table $OUTPUT_DIR/deblur-output/table.qza \
    --i-reference-sequences $REFERENCE_SEQUENCES \
    --p-perc-identity 0.97 \
    --output-dir $OUTPUT_DIR/cluster-output \
    --verbose