#!/bin/bash
# general_16s_SOP_v1_1_0.sh (qiime2-2022.8)

# Program performs a general qiime2 (qiime2-2022.8) pipeline and eventually produces a taxa bar plot
# and rooted phylogenetic tree.
#
# Make sure that the proper conda environment is active before running this script.

#------------ I/O Variables -----------#
INPUT_DIR="raw-data"
OUTPUT_DIR="output"

#-------------- Variables -------------#
METADATA="metadata.tab"
NCORES=8
REFERENCE_SEQUENCES="../resources/silva-138-99-seqs.qza"
CLASSIFIER="../resources/classifiers/silva-138-99-nb-classifier.qza"
SEPP="../resources/sepp/sepp-refs-silva-128.qza"

mkdir $OUTPUT_DIR

qiime tools import \
    --type SampleData[PairedEndSequencesWithQuality] \
    --input-path $INPUT_DIR \
    --output-path $OUTPUT_DIR/reads.qza \
    --input-format CasavaOneEightSingleLanePerSampleDirFmt

qiime cutadapt trim-paired \
    --i-demultiplexed-sequences $OUTPUT_DIR/reads.qza \
    --p-anywhere-f CCTACGGGNGGCWGCAG \
    --p-anywhere-r GACTACHVGGGTATCTAATCC \
    --p-discard-untrimmed \
    --p-no-indels \
    --p-cores $NCORES \
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
    --p-trim-length 270 \
    --p-sample-stats \
    --p-min-reads 1 \
    --p-jobs-to-start $NCORES \
    --output-dir $OUTPUT_DIR/deblur-output

qiime vsearch cluster-features-open-reference \
    --i-sequences $OUTPUT_DIR/deblur-output/representative_sequences.qza \
    --i-table $OUTPUT_DIR/deblur-output/table.qza \
    --i-reference-sequences $REFERENCE_SEQUENCES \
    --p-perc-identity 0.97 \
    --p-threads $NCORES \
    --output-dir $OUTPUT_DIR/cluster-output

qiime vsearch uchime-denovo \
    --i-table $OUTPUT_DIR/cluster-output/clustered_table.qza \
    --i-sequences $OUTPUT_DIR/cluster-output/clustered_sequences.qza \
    --output-dir $OUTPUT_DIR/chimera-filter-output

qiime feature-table filter-features \
    --i-table $OUTPUT_DIR/cluster-output/clustered_table.qza \
    --m-metadata-file $OUTPUT_DIR/chimera-filter-output/nonchimeras.qza \
    --o-filtered-table $OUTPUT_DIR/cluster-output/clustered_table_nonchimeric.qza
qiime feature-table filter-seqs \
    --i-data $OUTPUT_DIR/cluster-output/clustered_sequences.qza \
    --m-metadata-file $OUTPUT_DIR/chimera-filter-output/nonchimeras.qza \
    --o-filtered-data $OUTPUT_DIR/cluster-output/clustered_sequences_nonchimeric.qza

# qiime feature-classifier classify-sklearn \
#     --i-reads $OUTPUT_DIR/chimera-filter-output/nonchimeras_filtered.qza \
#     --i-classifier $CLASSIFIER \
#     --p-n-jobs $NCORES \
#     --output-dir $OUTPUT_DIR/taxa

# qiime taxa filter-table \
#     --i-table $OUTPUT_DIR/cluster-output/clustered_table_filtered.qza \
#     --i-taxonomy $OUTPUT_DIR/taxa/classification.qza \
#     --p-include p__ \
#     --p-exclude mitochondria,chloroplast \
#     --o-filtered-table $OUTPUT_DIR/cluster-output/clustered_table_filt_decontam.qza

# qiime feature-table summarize \
#     --i-table $OUTPUT_DIR/cluster-output/clustered_table_filt_decontam.qza \
#     --o-visualization $OUTPUT_DIR/cluster-output/clustered_table_filt_decontam.qzv

# qiime tools export \
#     --input-path $OUTPUT_DIR/cluster-output/clustered_table_filt_decontam.qza \
#     --output-path $OUTPUT_DIR/exported-feature-table

# qiime taxa barplot \
#     --i-table $OUTPUT_DIR/cluster-output/clustered_table_filt_decontam.qza \
#     --i-taxonomy $OUTPUT_DIR/taxa/classification.qza \
#     --m-metadata-file $METADATA \
#     --o-visualization $OUTPUT_DIR/taxa/taxa_barplot.qzv

# qiime phylogeny align-to-tree-mafft-fasttree \
#     --i-sequences $OUTPUT_DIR/chimera-filter-output/nonchimeras_filtered.qza \
#     --p-n-threads $NCORES \
#     --output-dir $OUTPUT_DIR/tree