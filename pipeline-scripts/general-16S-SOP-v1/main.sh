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
NCORES=4

FORWARD_PRIMER="CCTACGGGNGGCWGCAG"
REVERSE_PRIMER="GACTACHVGGGTATCTAATCC"

REFERENCE_SEQUENCES="../resources/silva-138-99-seqs.qza"
CLASSIFIER="../resources/classifiers/silva-138-99-nb-classifier.qza"
SEPP="../resources/sepp/sepp-refs-silva-128.qza"



########################################

#-------- Internal Variables ----------#
SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
SCRIPT_PARENT=$(dirname "$SCRIPT_DIR")
PROJECT_DIR=$(dirname "$SCRIPT_PARENT")

LOG_FILE=$PROJECT_DIR/$OUTPUT_DIR/log.log

#--------------- Script ---------------#
mkdir $PROJECT_DIR/$OUTPUT_DIR

bash $SCRIPT_DIR/_import_demultiplex.sh \
    $PROJECT_DIR/$INPUT_DIR \
    $PROJECT_DIR/$OUTPUT_DIR \
    $NCORES \
    $FORWARD_PRIMER \
    $REVERSE_PRIMER \
    2>&1 | tee -a $LOG_FILE

bash $SCRIPT_DIR/_quality_filter.sh \
    $PROJECT_DIR/$INPUT_DIR \
    $PROJECT_DIR/$OUTPUT_DIR \
    2>&1 | tee -a $LOG_FILE

bash $SCRIPT_DIR/_deblur_denoise_16S.sh \
    $PROJECT_DIR/$INPUT_DIR \
    $PROJECT_DIR/$OUTPUT_DIR \
    $NCORES \
    2>&1 | tee -a $LOG_FILE

bash $SCRIPT_DIR/_cluster_features_open_reference.sh \
    $PROJECT_DIR/$INPUT_DIR \
    $PROJECT_DIR/$OUTPUT_DIR \
    $REFERENCE_SEQUENCES \
    2>&1 | tee -a $LOG_FILE

bash $SCRIPT_DIR/_chimera_filtering_and_abundance_filtering.sh \
    $PROJECT_DIR/$INPUT_DIR \
    $PROJECT_DIR/$OUTPUT_DIR \
    2>&1 | tee -a $LOG_FILE

bash $SCRIPT_DIR/_classify_sklearn.sh \
    $PROJECT_DIR/$INPUT_DIR \
    $PROJECT_DIR/$OUTPUT_DIR \
    $CLASSIFIER \
    $NCORES \
    2>&1 | tee -a $LOG_FILE

bash $SCRIPT_DIR/_taxonomy_filtering.sh \
    $PROJECT_DIR/$INPUT_DIR \
    $PROJECT_DIR/$OUTPUT_DIR \
    2>&1 | tee -a $LOG_FILE

bash $SCRIPT_DIR/_taxa_barplot.sh \
    $PROJECT_DIR/$INPUT_DIR \
    $PROJECT_DIR/$OUTPUT_DIR \
    $PROJECT_DIR/$METADATA \
    2>&1 | tee -a $LOG_FILE