#!/bin/bash
#
# After importing data and checking the mean sample depth, filter out contaminants and
# output a taxonomy barplot.

for ARGUMENT in "$@"; do
   KEY=$(echo $ARGUMENT | cut -f1 -d=)

   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+1}"

   export "$KEY"="$VALUE"
done

BLEEDTHROUGH_VALUE=$(echo "${SAMPLE_DEPTH} * 0.001" | bc | sed 's/\..*//')
if [ -z "${BLEEDTHROUGH_VALUE}" ]; then
  BLEEDTHROUGH_VALUE=0
fi

qiime feature-table filter-features \
  --i-table ${QIIME_OUT_DIR}/denoise_output/table.qza \
  --p-min-frequency $BLEEDTHROUGH_VALUE \
  --p-min-samples 1 \
  --o-filtered-table ${QIIME_OUT_DIR}/denoise_output/denoise_table_filt.qza

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

qiime taxa barplot \
  --i-table ${QIIME_OUT_DIR}/denoise_output/denoise_table_final.qza \
  --i-taxonomy ${QIIME_OUT_DIR}/taxa/classification.qza \
  --o-visualization ${QIIME_OUT_DIR}/taxa/taxa_barplot.qzv