#------------ I/O Variables -----------#
INPUT_DIR="raw-data"
OUTPUT_DIR="output"

#-------------- Variables -------------#
METADATA="metadata.tab"
NCORES=8
REFERENCE_SEQUENCES="../resources/silva-138-99-seqs.qza"
CLASSIFIER="../resources/classifiers/silva-138-99-nb-classifier.qza"
SEPP="../resources/sepp/sepp-refs-silva-128.qza"

mkdir $OUTPUT_DIR

qiime tools import \
    --type SampleData[PairedEndSequencesWithQuality] \
    --input-path $INPUT_DIR \
    --output-path $OUTPUT_DIR/reads.qza \
    --input-format CasavaOneEightSingleLanePerSampleDirFmt

qiime cutadapt trim-paired \
    --i-demultiplexed-sequences $OUTPUT_DIR/reads.qza \
    --p-cores $NCORES \
    --p-front-f ACGCGHNRAACCTTACC \
    --p-front-r ACGGGCRGTGWGTRCAA \
    --p-discard-untrimmed \
    --p-no-indels \
    --o-trimmed-sequences $OUTPUT_DIR/reads_trimmed.qza

qiime vsearch join-pairs \
    --i-demultiplexed-seqs $OUTPUT_DIR/reads_trimmed.qza \
    --o-joined-sequences $OUTPUT_DIR/reads_trimmed_joined.qza

qiime quality-filter q-score \
    --i-demux $OUTPUT_DIR/reads_trimmed_joined.qza \
    --o-filter-stats $OUTPUT_DIR/filt_stats.qza \
    --o-filtered-sequences $OUTPUT_DIR/reads_trimmed_joined_filt.qza

qiime deblur denoise-16S \
    --i-demultiplexed-seqs $OUTPUT_DIR/reads_trimmed_joined_filt.qza \
    --p-trim-length -1 \
    --p-sample-stats \
    --p-jobs-to-start $NCORES \
    --p-min-reads 1 \
    --output-dir $OUTPUT_DIR/deblur_output

qiime feature-classifier classify-sklearn \
    --i-reads $OUTPUT_DIR/deblur_output/representative_sequences.qza \
    --i-classifier $CLASSIFIER \
    --p-n-jobs $NCORES \
    --output-dir $OUTPUT_DIR/taxa

qiime feature-table filter-features-conditionally \
    --i-table $OUTPUT_DIR/deblur_output/table.qza \
    --p-abundance 0.001 \
    --p-prevalence 0.001 \
    --o-filtered-table $OUTPUT_DIR/deblur_output/deblur_table_filt.qza

qiime taxa filter-table \
   --i-table $OUTPUT_DIR/deblur_output/deblur_table_filt.qza \
   --i-taxonomy $OUTPUT_DIR/taxa/classification.qza \
   --p-exclude mitochondria,chloroplast \
   --o-filtered-table $OUTPUT_DIR/deblur_output/deblur_table_filt_contam.qza

qiime feature-table filter-seqs \
   --i-data $OUTPUT_DIR/deblur_output/representative_sequences.qza \
   --i-table $OUTPUT_DIR/deblur_output/deblur_table_filt_contam.qza \
   --o-filtered-data $OUTPUT_DIR/deblur_output/rep_seqs_final.qza

qiime taxa barplot \
    --i-table $OUTPUT_DIR/deblur_output/deblur_table_filt_contam.qza \
    --i-taxonomy $OUTPUT_DIR/taxa/classification.qza \
    --m-metadata-file $METADATA \
    --o-visualization $OUTPUT_DIR/taxa/taxa_barplot.qzv