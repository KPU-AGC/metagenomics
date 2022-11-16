#!/bin/bash
# classify_sklearn.sh

#------------ I/O Variables -----------#
INPUT_DIR=$1
OUTPUT_DIR=$2
CLASSIFIER=$3
NCORES=$4

time qiime feature-classifier classify-sklearn \
    --i-reads $OUTPUT_DIR/chimera-filter-output/nonchimeras_filtered.qza \
    --i-classifier $CLASSIFIER \
    --p-n-jobs $NCORES \
    --output-dir $OUTPUT_DIR/taxa \
    --verbose