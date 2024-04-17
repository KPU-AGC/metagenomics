#!/bin/bash
#
# Perform a series of standardized QIIME2 commands for importing data.

FASTQ_DIR="/home/erick/projects/one-offs/20240416_edna/fastq"
QIIME_OUT_DIR="/home/erick/projects/one-offs/20240416_edna/qiime_output"
QIIME_DATA="/home/erick/data/qiime"

#./src/_generate_manifest.sh ${FASTQ_DIR}

./src/_import_data.sh \
  FASTQ_DIR=${FASTQ_DIR} \
  QIIME_OUT_DIR=${QIIME_OUT_DIR} \
  QIIME_DATA=${QIIME_DATA} \
  DENOISE="DADA2"

read -p "Mean sample depth: " SAMPLE_DEPTH
./src/_output_taxa_barplot.sh \
  FASTQ_DIR=${FASTQ_DIR} \
  QIIME_OUT_DIR=${QIIME_OUT_DIR} \
  QIIME_DATA=${QIIME_DATA} \
  SAMPLE_DEPTH="${SAMPLE_DEPTH}"