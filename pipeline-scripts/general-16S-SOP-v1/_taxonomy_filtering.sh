#!/bin/bash

#------------ I/O Variables -----------#
INPUT_DIR=$1
OUTPUT_DIR=$2

qiime taxa filter-table \
    --i-table $OUTPUT_DIR/cluster-output/clustered_table_filtered.qza \
    --i-taxonomy $OUTPUT_DIR/taxa/classification.qza \
    --p-include p__ \
    --p-exclude mitochondria,chloroplast \
    --o-filtered-table $OUTPUT_DIR/cluster-output/clustered_table_filt_decontam.qza

qiime feature-table summarize \
    --i-table $OUTPUT_DIR/cluster-output/clustered_table_filt_decontam.qza \
    --o-visualization $OUTPUT_DIR/cluster-output/clustered_table_filt_decontam.qzv

qiime tools export \
    --input-path $OUTPUT_DIR/cluster-output/clustered_table_filt_decontam.qza \
    --output-path $OUTPUT_DIR/exported-feature-table