#!/bin/bash
#
# Perform a series of standardized QIIME2 commands for importing data.

FASTQ_DIR="/home/erick/projects/one-offs/20240416_edna/fastq"
QIIME_OUT_DIR="/home/erick/projects/one-offs/20240416_edna/qiime_output"
QIIME_DATA="/home/erick/data/qiime"

./src/_import_data-deblur.sh \
  FASTQ_DIR=${FASTQ_DIR} \
  QIIME_OUT_DIR=${QIIME_OUT_DIR} \
  QIIME_DATA=${QIIME_DATA}

./src/_output_taxa_barplot.sh \
  FASTQ_DIR=${FASTQ_DIR} \
  QIIME_OUT_DIR=${QIIME_OUT_DIR} \
  QIIME_DATA=${QIIME_DATA} \
  BLEEDTHROUGH_VALUE=""