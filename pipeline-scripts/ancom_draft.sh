#!/bin/bash
# general-16s-SOP-v1-0-0.sh (qiime2-2022.8)

# Program performs a general qiime2 (qiime2-2022.8) pipeline and eventually produces a taxa bar plot.
# Make sure that the proper conda environment is active before running this script.

#------------ I/O Variables -----------#
INPUT_DIR="raw_data"
OUTPUT_DIR="output"

#-------------- Variables -------------#
METADATA="metadata.tab"
NCORES=8
REFERENCE_SEQUENCES="../resources/silva-138-99-seqs.qza"
CLASSIFIER="../resources/classifiers/qiaseq-v3v4-classifier.qza"
CATEGORY=$1

qiime composition add-pseudocount \
   --i-table $OUTPUT_DIR/cluster-output/clustered_table_filt_decontam.qza \
   --p-pseudocount 1 \
   --o-composition-table $OUTPUT_DIR/cluster-output/clustered_table_pseudocount.qza

qiime composition ancom \
   --i-table $OUTPUT_DIR/cluster-output/clustered_table_pseudocount.qza \
   --m-metadata-file $METADATA \
   --m-metadata-column $CATEGORY \
   --output-dir $OUTPUT_DIR/ancom_output
