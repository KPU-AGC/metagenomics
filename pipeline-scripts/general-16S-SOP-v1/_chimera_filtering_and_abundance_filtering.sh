#!/bin/bash
# _chimera_filtering_and_abundance_filtering.sh

#------------ I/O Variables -----------#
INPUT_DIR=$1
OUTPUT_DIR=$2


time qiime vsearch uchime-denovo \
    --i-table $OUTPUT_DIR/cluster-output/clustered_table.qza \
    --i-sequences $OUTPUT_DIR/cluster-output/clustered_sequences.qza \
    --output-dir $OUTPUT_DIR/chimera-filter-output \
    --verbose

time qiime feature-table filter-features-conditionally \
    --i-table $OUTPUT_DIR/cluster-output/clustered_table.qza \
    --p-abundance 0.01 \
    --p-prevalence 0.01 \
    --o-filtered-table $OUTPUT_DIR/cluster-output/clustered_table_filtered.qza \
    --verbose

time qiime feature-table filter-seqs \
    --i-data $OUTPUT_DIR/chimera-filter-output/nonchimeras.qza \
    --i-table $OUTPUT_DIR/cluster-output/clustered_table_filtered.qza \
    --o-filtered-data $OUTPUT_DIR/chimera-filter-output/nonchimeras_filtered.qza \
    --verbose