#!/bin/bash
# train_classifier.sh (qiime2-2022.8)

# Program performs a qiime2 (qiime2-2022.8) pipeline that extracts reads with a given primer and
# produces a trained classifier.
# Make sure that the proper conda environment is active before running this script.

#------------ I/O Variables -----------#
INPUT_SEQUENCES="silva-138-99-seqs.qza"
INPUT_REFERENCE_TAXONOMY="silva-138-99-tax.qza"
OUTPUT_NAME="qiaseq-v3v4"
OUTPUT_DIR="../classifiers"

#-------------- Variables -------------#
FORWARD="CCTACGGGNGGCWGCAG"
REVERSE="GACTACHVGGGTATCTAATCC"

qiime feature-classifier extract-reads \
    --i-sequences $INPUT_SEQUENCES \
    --p-f-primer $FORWARD \
    --p-r-primer $REVERSE \
    --p-trunc-len 200 \
    --p-min-length 100 \
    --p-max-length 400 \
    --o-reads $OUTPUT_NAME-ref-seqs.qza

qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads $OUTPUT_NAME-ref-seqs.qza \
  --i-reference-taxonomy $INPUT_REFERENCE_TAXONOMY \
  --o-classifier $OUTPUT_DIR/$OUTPUT_NAME-classifier.qza
