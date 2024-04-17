#!/bin/bash

## VARIABLES
QIIME2PATH=~/singularity/qiime2-2022.2.sif
PROJECTPATH=~/agc/projects/ion-torrent-protocols
PREFIX=ion-torrent-protocol
RUNTIME=$(date +'%Y%m%d-%H%M')
LOGFILE=$PROJECTPATH/outputs/$RUNTIME/$RUNTIME.log

## MAKE A DIRECTORY FOR THE OUTPUT
mkdir $PROJECTPATH/outputs/$RUNTIME

## IMPORT FASTQs AS QIIME2 ARTIFACTS
## The IonTorrent should've already trimmed the adapters + barcodes + primers.
## The FASTQ data should also be set up in single reads.
## A manifest file is then therefore required. Check this out on.
singularity exec \
    -B $PROJECTPATH/data:/data \
    -B $PROJECTPATH/outputs/$RUNTIME:/outputs \
    $QIIME2PATH \
    qiime tools import \
    --type 'SampleData[SequencesWithQuality]' \
    --input-path /data/manifest.tsv \
    --output-path /outputs/reads_trimmed.qza \
    --input-format SingleEndFastqManifestPhred33V2 \
    >> $LOGFILE

## SUMMARIZE FASTQs
## This is useful for visualizing the quality scores of the imported dataset.
singularity exec \
    -B $PROJECTPATH/data:/data \
    -B $PROJECTPATH/outputs/$RUNTIME:/outputs \
    $QIIME2PATH \
    qiime demux summarize \
    --i-data /outputs/reads_trimmed.qza \
    --o-visualization /outputs/reads_trimmed_stats.qzv \
    >> $LOGFILE

## FILTER OUT LOW-QUALITY READS
## This uses the default options for filtering out low-quality reads.
## There's documentation saying that IonTorrent data tends to be a little lower quality compared to
## Illumina data, so make sue to visualize the filtered reads as well.
singularity exec \
    -B $PROJECTPATH/data:/data \
    -B $PROJECTPATH/outputs/$RUNTIME:/outputs \
    $QIIME2PATH \
    qiime quality-filter q-score \
   --i-demux /outputs/reads_trimmed.qza \
   --o-filter-stats /outputs/filt_stats.qza \
   --o-filtered-sequences /outputs/reads_trimmed_filt.qza \
   >> $LOGFILE

singularity exec \
    -B $PROJECTPATH/data:/data \
    -B $PROJECTPATH/outputs/$RUNTIME:/outputs \
    $QIIME2PATH \
    qiime demux summarize \
    --i-data /outputs/reads_trimmed_filt.qza \
    --o-visualization /outputs/reads_trimmed_filt_summary.qzv \
    >> $LOGFILE

## RUNNING DADA2
## Most pipelines either use deblur or DADA2 to denoise the reads. The Langille Lab at Dal, along
## with many other forum sources, has done in-house testing which determines this to be the better
## option when dealing with IonTorrent data.

# --p-trim-left is recommended for IonTorrent
singularity exec \
    -B $PROJECTPATH/data:/data \
    -B $PROJECTPATH/outputs/$RUNTIME:/outputs \
    $QIIME2PATH \
    qiime dada2 denoise-single \
    --verbose \
   --i-demultiplexed-seqs /outputs/reads_trimmed_filt.qza \
   --p-trunc-len 0 \
   --p-trim-left 15 \
   --p-max-ee 3 \
   --output-dir /outputs/dada2_output \
    >> $LOGFILE

## SUMMARIZING DADA2 OUTPUT
singularity exec \
    -B $PROJECTPATH/data:/data \
    -B $PROJECTPATH/outputs/$RUNTIME:/outputs \
    $QIIME2PATH \
    qiime feature-table summarize \
    --i-table /outputs/dada2_output/table.qza \
    --o-visualization /outputs/dada2_output/dada2_table_summary.qzv \
    >> $LOGFILE

## READ COUNT TABLE
singularity exec \
    -B $PROJECTPATH/data:/data \
    -B $PROJECTPATH/outputs/$RUNTIME:/outputs \
    $QIIME2PATH \
    qiime tools export \
    --input-path /outputs/dada2_output/denoising_stats.qza \
    --output-path /outputs/dada2_output \
    >> $LOGFILE

mv \
    $PROJECTPATH/outputs/$RUNTIME/dada2_output/stats.tsv \
    $PROJECTPATH/outputs/$RUNTIME/dada2_output/dada2_stats.tsv \
    >> $LOGFILE

## ASSIGN TAXONOMY TO ASVs
singularity exec \
    -B $PROJECTPATH/data:/data \
    -B $PROJECTPATH/outputs/$RUNTIME:/outputs \
    $QIIME2PATH \
    qiime feature-classifier classify-sklearn \
    --i-classifier /data/gg-13-8-99-nb-classifier.qza \
    --i-reads /outputs/dada2_output/representative_sequences.qza \
    --o-classification /outputs/taxa/classification.qza \
    >> $LOGFILE

# singularity exec \
#     -B $PROJECTPATH/data:/data \
#     -B $PROJECTPATH/outputs/$RUNTIME:/outputs \
#     $QIIME2PATH \
#     qiime feature-classifier classify-consensus-vsearch \
#     --verbose \
#     --i-query /outputs/dada2_output/representative_sequences.qza \
#     --i-reference-reads /data/silva-138-99-seqs.qza \
#     --i-reference-taxonomy /data/silva-138-99-tax.qza \
#     --output-dir /outputs/taxa \
#     >> $LOGFILE

## VISUALIZE
singularity exec \
    -B $PROJECTPATH/data:/data \
    -B $PROJECTPATH/outputs/$RUNTIME:/outputs \
    $QIIME2PATH \
    qiime tools export \
    --input-path /outputs/taxa/classification.qza \
    --output-path /outputs/taxa \
    >> $LOGFILE

## GENERATE A TREE FOR PHYLOGENETIC DIVERSITY ANALYSIS
singularity exec \
    -B $PROJECTPATH/data:/data \
    -B $PROJECTPATH/outputs/$RUNTIME:/outputs \
    $QIIME2PATH \
    qiime phylogeny align-to-tree-mafft-fasttree \
    --i-sequences /outputs/dada2_output/representative_sequences.qza \
    --o-alignment /outputs/aligned_reprepresentative_sequences.qza \
    --o-masked-alignment /outputs/masked_aligned_representative_sequences.qza \
    --o-tree /outputs/unrooted_tree.qza \
    --o-rooted-tree /outputs/rooted_tree.qza \
    >> $LOGFILE

## TAXA BARPLOTS
singularity exec \
    -B $PROJECTPATH/data:/data \
    -B $PROJECTPATH/outputs/$RUNTIME:/outputs \
    $QIIME2PATH \
    qiime taxa barplot \
    --i-table /outputs/dada2_output/table.qza \
    --i-taxonomy /outputs/taxa/classification.qza \
    --o-visualization /outputs/taxa-bar-plots.qzv \
    >> $LOGFILE
