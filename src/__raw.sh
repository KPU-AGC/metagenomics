#!/bin bash
#
# Perform a series of standardized QIIME2 commands for importing data.

for ARGUMENT in "$@"; do
   KEY=$(echo $ARGUMENT | cut -f1 -d=)

   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+1}"

   export "$KEY"="$VALUE"
done

qiime_data="/home/erick/data/qiime"

qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path ${FASTQ_DIR}/fastq.manifest \
  --output-path ${QIIME_OUT_DIR}/paired-end-seqs.qza \
  --input-format PairedEndFastqManifestPhred33V2

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs ${QIIME_OUT_DIR}/paired-end-seqs.qza \
  --p-trunc-len-f 250 \
  --p-trunc-len-r 210 \
  --p-max-ee-f 2 \
  --p-max-ee-r 3 \
  --p-n-threads 16 \
  --output-dir ${QIIME_OUT_DIR}/dada2_output

qiime feature-table summarize \
 --i-table ${QIIME_OUT_DIR}/dada2_output/table.qza \
 --o-visualization ${QIIME_OUT_DIR}/dada2_output/deblur_table_summary.qzv

qiime feature-classifier classify-sklearn \
  --i-reads ${QIIME_OUT_DIR}/dada2_output/representative_sequences.qza \
  --i-classifier ${QIIME_DATA}/silva-138-99-nb-classifier.qza \
  --p-n-jobs 16 \
  --p-reads-per-batch 5000 \
  --output-dir ${QIIME_OUT_DIR}/taxa

# MEAN_SAMPLE_DEPTH=3337
# BLEEDTHROUGH_VALUE=$(echo "$MEAN_SAMPLE_DEPTH * 0.001" | bc | sed 's/\..*//')
# qiime feature-table filter-features \
#  --i-table ${QIIME_OUT_DIR}/dada2_output/table.qza \
#  --p-min-frequency $BLEEDTHROUGH_VALUE \
#  --p-min-samples 1 \
#  --o-filtered-table ${QIIME_OUT_DIR}/dada2_output/dada2_table_filt.qza

# qiime taxa filter-table \
#  --i-table ${QIIME_OUT_DIR}/dada2_output/dada2_table_filt.qza \
#  --i-taxonomy ${QIIME_OUT_DIR}/taxa/classification.qza \
#  --p-exclude mitochondria,chloroplast \
#  --o-filtered-table ${QIIME_OUT_DIR}/dada2_output/dada2_table_filt_contam.qza

# qiime feature-table summarize \
#  --i-table ${QIIME_OUT_DIR}/dada2_output/dada2_table_filt_contam.qza \
#  --o-visualization ${QIIME_OUT_DIR}/dada2_output/dada2_table_filt_contam_summary.qzv

# rarefaction_val=1000
# qiime diversity alpha-rarefaction \
#  --i-table ${QIIME_OUT_DIR}/dada2_output/dada2_table_filt_contam.qza \
#  --p-max-depth $rarefaction_val \
#  --p-steps 20 \
#  --p-metrics 'observed_features' \
#  --o-visualization ${QIIME_OUT_DIR}/rarefaction_curves_test.qzv

# cp ${QIIME_OUT_DIR}/dada2_output/dada2_table_filt_contam.qza ${QIIME_OUT_DIR}/dada2_output/dada2_table_final.qza

# qiime feature-table filter-seqs \
#  --i-data ${QIIME_OUT_DIR}/dada2_output/representative_sequences.qza \
#  --i-table ${QIIME_OUT_DIR}/dada2_output/dada2_table_final.qza \
#  --o-filtered-data ${QIIME_OUT_DIR}/dada2_output/rep_seqs_final.qza

# qiime taxa barplot \
#    --i-table ${QIIME_OUT_DIR}/dada2_output/dada2_table_final.qza \
#    --i-taxonomy ${QIIME_OUT_DIR}/taxa/classification.qza \
#    --m-metadata-file ${QIIME_OUT_DIR}/../sample_metadata.tsv \
#    --o-visualization ${QIIME_OUT_DIR}/taxa/taxa_barplot.qzv

#mkdir -p ${QIIME_OUT_DIR}/tree
#qiime alignment mafft \
#  --i-sequences ${QIIME_OUT_DIR}/dada2_output/rep_seqs_final.qza \
#  --o-alignment ${QIIME_OUT_DIR}/tree/aligned_rep_seqs.qza

#qiime alignment mask \
#  --i-alignment ${QIIME_OUT_DIR}/tree/aligned_rep_seqs.qza \
#  --o-masked-alignment ${QIIME_OUT_DIR}/tree/masked_aligned_rep_seqs.qza

#qiime phylogeny fasttree \
##  --i-alignment ${QIIME_OUT_DIR}/tree/masked_aligned_rep_seqs.qza \
#  --o-tree ${QIIME_OUT_DIR}/tree/unrooted_tree.qza

# qiime phylogeny midpoint-root \
#   --i-tree ${QIIME_OUT_DIR}/tree/unrooted_tree.qza \
#   --o-rooted-tree ${QIIME_OUT_DIR}/tree/rooted_tree.qza

# qiime diversity core-metrics-phylogenetic \
#   --i-phylogeny ${QIIME_OUT_DIR}/tree/rooted_tree.qza \
#   --i-table ${QIIME_OUT_DIR}/dada2_output/dada2_table_final.qza \
#   --p-sampling-depth 5000 \
#   --m-metadata-file ${QIIME_OUT_DIR}/../sample_metadata.tsv \
#   --output-dir ${QIIME_OUT_DIR}/core-metrics-results


# METRIC=bray_curtis
# META=diet
# qiime diversity beta-group-significance \
#   --i-distance-matrix ${QIIME_OUT_DIR}/core-metrics-results/"$METRIC"_distance_matrix.qza \
#   --m-metadata-file ${QIIME_OUT_DIR}/../sample_metadata.tsv \
#   --m-metadata-column $META \
#   --o-visualization ${QIIME_OUT_DIR}/core-metrics-results/"$METRIC"_"$META"_permanova_results.qzv \
#   --p-pairwise


# mkdir ${QIIME_OUT_DIR}/methanogens
# qiime taxa filter-table \
#   --i-table ${QIIME_OUT_DIR}/dada2_output/dada2_table_final.qza \
#   --i-taxonomy ${QIIME_OUT_DIR}/taxa/classification.qza \
#   --p-include "c__methanobacteria" \
#   --o-filtered-table ${QIIME_OUT_DIR}/methanogens/methanogens-table.qza

# qiime diversity core-metrics-phylogenetic \
#   --i-phylogeny ${QIIME_OUT_DIR}/tree/rooted_tree.qza \
#   --i-table ${QIIME_OUT_DIR}/methanogens/methanogens-table.qza \
#   --p-sampling-depth 100 \
#   --m-metadata-file ${QIIME_OUT_DIR}/../sample_metadata.tsv \
#   --output-dir ${QIIME_OUT_DIR}/methanogens/core-metrics-results

# METRIC=unweighted_unifrac
# qiime tools export \
#   --input-path ${QIIME_OUT_DIR}/core-metrics-results/"$METRIC"_pcoa_results.qza \
#   --output-path ${QIIME_OUT_DIR}/pcoa_results_exported

# METRIC=bray_curtis
# META=breed
# qiime diversity beta-group-significance \
#   --i-distance-matrix ${QIIME_OUT_DIR}/core-metrics-results/"$METRIC"_distance_matrix.qza \
#   --m-metadata-file ${QIIME_OUT_DIR}/../sample_metadata.tsv \
#   --m-metadata-column $META \
#   --o-visualization ${QIIME_OUT_DIR}/core-metrics-results/"$METRIC"_"$META"_permanova_results.qzv \
#   --p-pairwise


#qiime diversity alpha \
#  --i-table ${QIIME_OUT_DIR}/dada2_output/dada2_table_final.qza \
#  --p-metric shannon \
#  --o-alpha-diversity ${QIIME_OUT_DIR}/shannon_diversity.qza

#qiime tools export \
#  --input-path ${QIIME_OUT_DIR}/shannon_diversity.qza \
#  --output-path ${QIIME_OUT_DIR}/observed_otus_individual_exported

#qiime tools export \
#  --input-path ${QIIME_OUT_DIR}/dada2_output/dada2_table_final.qza \
#  --output-path ${QIIME_OUT_DIR}/table

#biom convert \
#  -i ${QIIME_OUT_DIR}/table/feature-table.biom \
#  -o ${QIIME_OUT_DIR}/table/feature-table.tsv \
#  --to-tsv

