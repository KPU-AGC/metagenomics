#!/bin bash
#
# Perform a series of standardized QIIME2 commands for importing data.

./src/_import_data-deblur.sh \
  FASTQ_DIR="" \
  QIIME_OUT_DIR="" \
  QIIME_DATA=""

./src/_import_data.sh \
  FASTQ_DIR="" \
  QIIME_OUT_DIR="" \
  QIIME_DATA="" \
  BLEEDTHROUGH_VALUE=""