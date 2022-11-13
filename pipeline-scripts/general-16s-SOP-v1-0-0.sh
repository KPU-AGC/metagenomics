#!/bin/bash
# general-16s-SOP-v1-0-0.sh (qiime2-2022.8)

# Program performs a general qiime2 (qiime2-2022.8) pipeline and eventually produces a taxa bar plot.
# Make sure that the proper conda environment is active before running this script.

#------------ I/O Variables -----------#
INPUT_DIR="test_data/"
OUTPUT_DIR="output/"

#-------------- Variables -------------#
METADATA="metadata.txt"
NCORES=4
REFERENCE_SEQUENCES="../resources/silva-138-99-seqs.qza"
CLASSIFIER="../resources/gg-13-8-99-nb-classifier.qza"


mkdir $OUTPUT_DIR

qiime tools import \
    --type SampleData[PairedEndSequencesWithQuality] \
    --input-path $INPUT_DIR \
    --output-path $OUTPUT_DIR/reads.qza \
    --input-format CasavaOneEightSingleLanePerSampleDirFmt

qiime cutadapt trim-paired \
    --i-demultiplexed-sequences $OUTPUT_DIR/reads.qza \
    --p-cores $NCORES \
    --p-anywhere-f CCTACGGGNGGCWGCAG \
    --p-anywhere-r GACTACHVGGGTATCTAATCC \
    --p-discard-untrimmed \
    --p-no-indels \
    --o-trimmed-sequences $OUTPUT_DIR/reads_trimmed.qza

qiime vsearch join-pairs \
    --i-demultiplexed-seqs $OUTPUT_DIR/reads_trimmed.qza \
    --o-joined-sequences $OUTPUT_DIR/reads_trimmed_joined.qza

qiime quality-filter q-score \
    --i-demux $OUTPUT_DIR/reads_trimmed_joined.qza \
    --o-filter-stats $OUTPUT_DIR/filt_stats.qza \
    --o-filtered-sequences $OUTPUT_DIR/reads_trimmed_joined_filt.qza

qiime deblur denoise-16S \
    --i-demultiplexed-seqs $OUTPUT_DIR/reads_trimmed_joined_filt.qza \
    --p-trim-length 250 \
    --p-sample-stats \
    --p-jobs-to-start $NCORES \
    --p-min-reads 1 \
    --output-dir $OUTPUT_DIR/deblur_output

qiime vsearch cluster-features-open-reference \
    --i-sequences $OUTPUT_DIR/deblur_output/representative_sequences.qza \
    --i-table $OUTPUT_DIR/deblur_output/table.qza \
    --i-reference-sequences $REFERENCE_SEQUENCES \
    --p-perc-identity 0.97 \
    --output-dir $OUTPUT_DIR/cluster_output

qiime feature-classifier classify-sklearn \
    --i-reads $OUTPUT_DIR/cluster_output/clustered_sequences.qza \
    --i-classifier $CLASSIFIER \
    --p-n-jobs $NCORES \
    --output-dir $OUTPUT_DIR/taxa

qiime taxa filter-table \
    --i-table $OUTPUT_DIR/cluster_output/clustered_table.qza \
    --i-taxonomy $OUTPUT_DIR/taxa/classification.qza \
    --p-include p__ \
    --p-exclude mitochondria,chloroplast \
    --o-filtered-table $OUTPUT_DIR/cluster_output/clustered_table_filt_contam.qza

qiime taxa barplot \
    --i-table $OUTPUT_DIR/cluster_output/clustered_table_filt_contam.qza \
    --i-taxonomy taxa/classification.qza \
    --m-metadata-file $METADATA \
    --o-visualization $OUTPUT_DIR/taxa/taxa_barplot.qzv
