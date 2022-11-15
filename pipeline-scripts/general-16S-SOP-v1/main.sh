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

FORWARD_PRIMER="CCTACGGGNGGCWGCAG"
REVERSE_PRIMER="GACTACHVGGGTATCTAATCC"

REFERENCE_SEQUENCES="../resources/silva-138-99-seqs.qza"
CLASSIFIER="../resources/classifiers/silva-138-99-nb-classifier.qza"
SEPP="../resources/sepp/sepp-refs-silva-128.qza"

bash general-16S-SOP-v1/_import_demultiplex.sh \
    $INPUT_DIR \
    $OUTPUT_DIR \
    $NCORES \
    $FORWARD_PRIMER \
    $REVERSE_PRIMER