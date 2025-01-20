#!/bin/bash
#
# Perform a series of standardized QIIME2 commands for importing data.
set -eux

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname ${SCRIPT_DIR})"
FASTQ_DIR=${PROJECT_DIR}/fastq
QIIME_OUT_DIR=${PROJECT_DIR}/qiime_output
QIIME_DATA="/home/agc/Documents/ericksam/qiime/resources"

function parse_keyword_arguments {
  for ARGUMENT in "$@"; do
    KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
    VALUE=$(echo "$ARGUMENT" | cut -f2- -d=)
    export "$KEY"="$VALUE"
  done
}

function generate_manifest {
  bash ./src/_generate_manifest.sh ${FASTQ_DIR}
}

function import_data {
  parse_keyword_arguments "$@"

  qiime tools import \
    --type "${type:-'SampleData[PairedEndSequencesWithQuality]'}" \
    --input-path "${input_path:-${FASTQ_DIR}/fastq.manifest}" \
    --output-path "${output_path:-${QIIME_OUT_DIR}/seqs_paired_end.qza}" \
    --input-format "${input_format:-PairedEndFastqManifestPhred33V2}"
}

function do_dada2 {
  parse_keyword_arguments "$@"

  qiime dada2 denoise-paired \
    --i-demultiplexed-seqs ${QIIME_OUT_DIR}/seqs_paired_end.qza \
    --p-trunc-len-f "${p_trunc_len_f:-250}" \
    --p-trunc-len-r "${p_trunc_len_r:-250}" \
    --p-max-ee-f "${p_max_ee_f:-2}" \
    --p-max-ee-r "${p_max_ee_r:-3}" \
    --p-n-threads "${p_n_threads:-16}" \
    --output-dir ${QIIME_OUT_DIR}/denoise_output

  qiime feature-table summarize \
    --i-table ${QIIME_OUT_DIR}/denoise_output/table.qza \
    --o-visualization ${QIIME_OUT_DIR}/denoise_output/denoise_table_summary.qzv
}

function classify_sklearn {
  parse_keyword_arguments "$@"

  qiime feature-classifier classify-sklearn \
    --i-reads ${QIIME_OUT_DIR}/denoise_output/representative_sequences.qza \
    --i-classifier "${QIIME_DATA}/${classifier:-/silva-138-99-nb-classifier.qza}" \
    --p-n-jobs 16 \
    --p-reads-per-batch 5000 \
    --output-dir ${QIIME_OUT_DIR}/taxa
}

function filter_bleedthrough {
  SAMPLE_DEPTH=${1}
  BLEEDTHROUGH_VALUE=$(echo "${SAMPLE_DEPTH} * 0.001" | bc | sed 's/\..*//')
  if [ -z "${BLEEDTHROUGH_VALUE}" ]; then
    BLEEDTHROUGH_VALUE=0
  fi

  qiime feature-table filter-features \
    --i-table ${QIIME_OUT_DIR}/denoise_output/table.qza \
    --p-min-frequency ${BLEEDTHROUGH_VALUE} \
    --p-min-samples 1 \
    --o-filtered-table ${QIIME_OUT_DIR}/denoise_output/denoise_table_filt.qza
}

function filter_table {
  qiime taxa filter-table \
    --i-table ${QIIME_OUT_DIR}/denoise_output/denoise_table_filt.qza \
    --i-taxonomy ${QIIME_OUT_DIR}/taxa/classification.qza \
    --p-exclude mitochondria,chloroplast \
    --o-filtered-table ${QIIME_OUT_DIR}/denoise_output/denoise_table_filt_contam.qza

  qiime feature-table summarize \
  --i-table ${QIIME_OUT_DIR}/denoise_output/denoise_table_filt_contam.qza \
  --o-visualization ${QIIME_OUT_DIR}/denoise_output/denoise_table_filt_contam_summary.qzv

  cp ${QIIME_OUT_DIR}/denoise_output/denoise_table_filt_contam.qza ${QIIME_OUT_DIR}/denoise_output/denoise_table_final.qza

  qiime feature-table filter-seqs \
    --i-data ${QIIME_OUT_DIR}/denoise_output/representative_sequences.qza \
    --i-table ${QIIME_OUT_DIR}/denoise_output/denoise_table_final.qza \
    --o-filtered-data ${QIIME_OUT_DIR}/denoise_output/rep_seqs_final.qza
}

function output_taxa_barplot {
  qiime taxa barplot \
    --i-table ${QIIME_OUT_DIR}/denoise_output/denoise_table_final.qza \
    --i-taxonomy ${QIIME_OUT_DIR}/taxa/classification.qza \
    --o-visualization ${QIIME_OUT_DIR}/taxa/taxa_barplot.qzv
}

generate_manifest
import_data
do_dada2
classify_sklearn classifier=silva-138-99-nb-classifier.qza
filter_bleedthrough 17430
filter_table
output_taxa_barplot
