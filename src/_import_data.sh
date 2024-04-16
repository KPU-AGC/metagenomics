#!/bin/bash
#
# Perform a series of standardized QIIME2 commands for importing data.

for ARGUMENT in "$@"; do
   KEY=$(echo $ARGUMENT | cut -f1 -d=)

   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+1}"

   export "$KEY"="$VALUE"
done

qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path ${FASTQ_DIR}/fastq.manifest \
  --output-path ${QIIME_OUT_DIR}/seqs_paired_end.qza \
  --input-format PairedEndFastqManifestPhred33V2

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs ${QIIME_OUT_DIR}/seqs_paired_end.qza \
  --p-trunc-len-f 250 \
  --p-trunc-len-r 210 \
  --p-max-ee-f 2 \
  --p-max-ee-r 3 \
  --p-n-threads 16 \
  --output-dir ${QIIME_OUT_DIR}/denoise_output

qiime feature-table summarize \
 --i-table ${QIIME_OUT_DIR}/denoise_output/table.qza \
 --o-visualization ${QIIME_OUT_DIR}/denoise_output/denoise_table_summary.qzv

qiime feature-classifier classify-sklearn \
  --i-reads ${QIIME_OUT_DIR}/denoise_output/representative_sequences.qza \
  --i-classifier ${QIIME_DATA}/silva-138-99-nb-classifier.qza \
  --p-n-jobs 16 \
  --p-reads-per-batch 5000 \
  --output-dir ${QIIME_OUT_DIR}/taxa