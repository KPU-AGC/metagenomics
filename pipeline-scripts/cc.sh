METADATA=""
NCORES=1
mkdir reads_qza
    
qiime tools import \
    --type SampleData[PairedEndSequencesWithQuality] \
    --input-path raw_data/ \
    --output-path reads_qza/reads.qza \
    --input-format CasavaOneEightSingleLanePerSampleDirFmt

qiime cutadapt trim-paired \
    --i-demultiplexed-sequences reads_qza/reads.qza \
    --p-cores $NCORES \
    --p-front-f ACGCGHNRAACCTTACC \
    --p-front-r ACGGGCRGTGWGTRCAA \
    --p-discard-untrimmed \
    --p-no-indels \
    --o-trimmed-sequences reads_qza/reads_trimmed.qza

qiime demux summarize \
    --i-data reads_qza/reads_trimmed.qza \
    --o-visualization reads_qza/reads_trimmed_summary.qzv

qiime vsearch join-pairs \
    --i-demultiplexed-seqs reads_qza/reads_trimmed.qza \
    --o-joined-sequences reads_qza/reads_trimmed_joined.qza

qiime quality-filter q-score \
    --i-demux reads_qza/reads_trimmed_joined.qza \
    --o-filter-stats filt_stats.qza \
    --o-filtered-sequences reads_qza/reads_trimmed_joined_filt.qza

qiime demux summarize \
    --i-data reads_qza/reads_trimmed_joined_filt.qza \
    --o-visualization reads_qza/reads_trimmed_joined_filt_summary.qzv

qiime deblur denoise-16S \
    --i-demultiplexed-seqs reads_qza/reads_trimmed_joined_filt.qza \
    --p-trim-length -1 \
    --p-sample-stats \
    --p-jobs-to-start $NCORES \
    --p-min-reads 1 \
    --output-dir deblur_output

qiime feature-table summarize \
    --i-table deblur_output/table.qza \
    --o-visualization deblur_output/deblur_table_summary.qzv

qiime feature-classifier classify-sklearn \
    --i-reads deblur_output/representative_sequences.qza \
    --i-classifier /home/shared/taxa_classifiers/qiime2-2020.8_classifiers/silva-138-99-nb-classifier.qza \
    --p-n-jobs $NCORES \
    --output-dir taxa

qiime feature-table tabulate-seqs \
    --i-data deblur_output/representative_sequences.qza \
    --o-visualization deblur_output/representative_sequences.qzv

qiime feature-table filter-features \
   --i-table deblur_output/table.qza \
   --p-min-frequency X \
   --p-min-samples 1 \
   --o-filtered-table deblur_output/deblur_table_filt.qza

qiime taxa filter-table \
   --i-table deblur_output/deblur_table_filt.qza \
   --i-taxonomy taxa/classification.qza \
   --p-exclude mitochondria,chloroplast \
   --o-filtered-table deblur_output/deblur_table_filt_contam.qza

qiime feature-table summarize \
   --i-table deblur_output/deblur_table_filt_contam.qza \
   --o-visualization deblur_output/deblur_table_filt_contam_summary.qzv

qiime diversity alpha-rarefaction \
   --i-table deblur_output/deblur_table_filt_contam.qza \
   --p-max-depth X \
   --p-steps 20 \
   --p-metrics 'observed_features' \
   --o-visualization rarefaction_curves_test.qzv

qiime feature-table filter-samples \
   --i-table deblur_output/deblur_table_filt_contam.qza \
   --p-min-frequency SET_CUTOFF \
   --o-filtered-table deblur_output/deblur_table_final.qza

qiime feature-table filter-seqs \
   --i-data deblur_output/representative_sequences.qza \
   --i-table deblur_output/deblur_table_final.qza \
   --o-filtered-data deblur_output/rep_seqs_final.qza

qiime feature-table summarize \
   --i-table deblur_output/deblur_table_final.qza \
   --o-visualization deblur_output/deblur_table_final_summary.qzv