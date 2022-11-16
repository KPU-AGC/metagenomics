#!/bin/bash

#------------ I/O Variables -----------#
INPUT_DIR=$1
OUTPUT_DIR=$2
METADATA=$3

qiime taxa barplot \
    --i-table $OUTPUT_DIR/cluster-output/clustered_table_filt_decontam.qza \
    --i-taxonomy $OUTPUT_DIR/taxa/classification.qza \
    --m-metadata-file $METADATA \
    --o-visualization $OUTPUT_DIR/taxa/taxa_barplot.qzv