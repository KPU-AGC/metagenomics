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

while getopts m:M: flag
do
    case "${flag}" in
        m) MIN_SAMPLING_DEPTH=${OPTARG};;
        M) MAX_SAMPLING_DEPTH=${OPTARG};;
    esac
done

qiime diversity alpha-rarefaction \
   --i-table $OUTPUT_DIR/cluster-output/clustered_table_filt_decontam.qza \
   --p-max-depth $MAX_SAMPLING_DEPTH \
   --p-steps 20 \
   --i-phylogeny $OUTPUT_DIR/tree/rooted-tree.qza \
   --m-metadata-file $METADATA \
   --output-dir $OUTPUT_DIR/alpha-rarefaction

qiime diversity alpha-rarefaction \
   --i-table $OUTPUT_DIR/cluster-output/clustered_table_filt_decontam.qza \
   --p-max-depth $MAX_SAMPLING_DEPTH \
   --p-steps 20 \
   --i-phylogeny $OUTPUT_DIR/tree/rooted-tree.qza \
   --o-visualization $OUTPUT_DIR/alpha-rarefaction/rarefaction_curves_eachsample.qzv

qiime diversity core-metrics-phylogenetic \
   --i-table $OUTPUT_DIR/cluster-output/clustered_table_filt_decontam.qza \
   --i-phylogeny $OUTPUT_DIR/tree/rooted-tree.qza \
   --p-sampling-depth $MIN_SAMPLING_DEPTH \
   --m-metadata-file $METADATA \
   --p-n-jobs-or-threads $NCORES \
   --output-dir diversity
