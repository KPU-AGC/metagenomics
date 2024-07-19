#!/bin/bash
#
# Perform a series of standardized QIIME2 commands for importing data.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname ${SCRIPT_DIR})"
FASTQ_DIR=${PROJECT_DIR}/fastq
QIIME_OUT_DIR=${PROJECT_DIR}/qiime_output
QIIME_DATA="/home/erick/data/qiime"

#./src/_generate_manifest.sh ${FASTQ_DIR}

bash ./src/_import_data.sh \
  FASTQ_DIR=${FASTQ_DIR} \
  QIIME_OUT_DIR=${QIIME_OUT_DIR} \
  QIIME_DATA=${QIIME_DATA} \
  DENOISE="DADA2"

read -p "Mean sample depth: " SAMPLE_DEPTH
bash ./src/_output_taxa_barplot.sh \
  FASTQ_DIR=${FASTQ_DIR} \
  QIIME_OUT_DIR=${QIIME_OUT_DIR} \
  QIIME_DATA=${QIIME_DATA} \
  SAMPLE_DEPTH="${SAMPLE_DEPTH}"
