#!/bin/bash
cat << EOF
---------------------------------------------------
                   ▓▓░  ▓▓▓  ░▓▓▓
  -. .-.   .-. .- ▓░ ▓░▓░   ░▓  ░▓ -. .-.   .-. .-
  ||\|||\ /|||\|| ▓▓▓▓░▓░░▓▓░▓     ||\|||\ /|||\||
  |/ \|||\|||/ \| ▓░ ▓░▓░ ░▓░▓  ░▓ |/ \|||\|||/ \|
  ¯   '-¯ '-'   ' ▓░ ▓░ ▓▓▓  ░▓▓▓  ¯   '-¯ '-'   '
 T H E  A P P L I E D  G E N O M I C S  C E N T R E
          --- Coding a better harvest ---
---------------------------------------------------
The  purpose   of  this  script   is   to   perform
metagenomic  analyses  on  NGS runs  related  to an
internal project  assessing  the consistency of our
data  quality   and   to  develop   a  standardized
protocol for NGS
EOF
# ---------------------------------------------------
# SETTING UP DIRECTORIES TO BE USED
# ---------------------------------------------------
# *WHICH_RUN, IMPORT_FASTQS, and SAMPLE_SHEET need to be changed for each run
# *Change WHICH_RUN for each dataset that you're analyzing
# ---------------------------------------------------
WHICH_RUN=20240911-Norgen_Nano_16S_ITS # Including this to help remove human error, just changing this one variable will enable formatting this workflow for any datasets
FASTQS_LOC=fastq_trimmed/surviv_pairs_fastqs # This will vary between "Basecalls" and "Alignment_1"
# *Change the subfolder for IMPORT_FASTQS depending on the dataset
# Root directories for the project
# ---------------------------------------------------
RAW_DATA=~/Documents/paddy/NGS_microbial_samples_testing/data/raw_data
FASTQS=${RAW_DATA}/$WHICH_RUN/$FASTQS_LOC
ANALYZED_DATA=~/Documents/paddy/NGS_microbial_samples_testing/data/analyzed_data
QIIME_DATA=${RAW_DATA}/$WHICH_RUN/qiime_data
QIIME_ANALYSES=${ANALYZED_DATA}/$WHICH_RUN
# Manifest and metadata files
# ---------------------------------------------------
IMPORT_MANIFEST=${RAW_DATA}/$WHICH_RUN/qiime_import_manifest_PairedEndFastqManifestPhred33V2.tsv
THE_16S_IMPORT_MANIFEST=${RAW_DATA}/$WHICH_RUN/qiime_import_manifest_PairedEndFastqManifestPhred33V2_16S.tsv
ITS_IMPORT_MANIFEST=${RAW_DATA}/$WHICH_RUN/qiime_import_manifest_PairedEndFastqManifestPhred33V2_ITS.tsv
MC_IMPORT_MANIFEST=${RAW_DATA}/$WHICH_RUN/qiime_import_manifest_PairedEndFastqManifestPhred33V2_MC.tsv
THE_16S_SAMPLE_METADATA=${RAW_DATA}/$WHICH_RUN/qiime2_format_metadata_16S.tsv
ITS_SAMPLE_METADATA=${RAW_DATA}/$WHICH_RUN/qiime2_format_metadata_ITS.tsv
MC_SAMPLE_METADATA=${RAW_DATA}/$WHICH_RUN/qiime2_format_metadata_MC.tsv
# Importing data as well as then denoising, generating feature table, and collecting stats
# ---------------------------------------------------
THE_16S_IMPORT_MANIFEST=${QIIME_DATA}/import_data_16S.qza
ITS_IMPORT_MANIFEST=${QIIME_DATA}/import_data_ITS.qza
REP_SEQS_QZA=${QIIME_DATA}/rep_seqs.qza
REP_SEQS_QZV=${QIIME_DATA}/rep_seqs.qzv
FEATURE_TABLE=${QIIME_DATA}/feature_table.qza
REP_SEQS_STATS=${QIIME_DATA}/rep_seqs_stats.qza
STATS_VIS=${QIIME_DATA}/rep_seqs_stats.qzv
FEATURE_TABLE_VIS=${QIIME_DATA}/feature_table.qzv
# Qiime phylogeny
# ---------------------------------------------------
MSA_QZA=${QIIME_DATA}/mafft_MSA.qza
MSA_MASKED_QZA=${QIIME_DATA}/mafft_MSA_masked.qza
UNROOTED_TREE=${QIIME_DATA}/unrooted_tree.qza
ROOTED_TREE=${QIIME_DATA}/rooted_tree.qza
FAITH_PD_VECTOR=${QIIME_ANALYSES}/core-metrics-results/faith_pd_vector.qza
FAITH_PD_GROUP_SIGNIF_VIS=${QIIME_ANALYSES}/core-metrics-results/faith_pd_group_significance.qzv
SHANNON_VECTOR=${QIIME_ANALYSES}/core-metrics-results/shannon_vector.qza
SHANNON_GROUP_SIGNIF_VIS=${QIIME_ANALYSES}/core-metrics-results/shannon_group_significance.qzv
## 16S Taxonomic Assignment
## ---------------------------------------------------
#16S_TAXONOMY_CLASSIFER=${RAW_DATA}/silva-138-99-nb-classifier.qza
#16S_TAXONOMY_QZA=${QIIME_DATA}/16S_assigned_taxonomy.qza
#16S_TAXONOMY_QZV=${QIIME_DATA}/16S_assigned_taxonomy.qzv
## ITS Taxonomic Assignment
## ---------------------------------------------------
#ITS_TAXONOMY_CLASSIFER=${RAW_DATA}/...
#ITS_TAXONOMY_QZA=${QIIME_DATA}/ITS_assigned_taxonomy.qza
#ITS_TAXONOMY_QZV=${QIIME_DATA}/ITS_assigned_taxonomy.qzv
# Visualization of alpha and beta diversity, and generate barplots 
# ---------------------------------------------------
ALPHA_RAREFACTION=${QIIME_ANALYSES}/alpha_rarefaction.qzv
UW_UF_DIST_MAT=${QIIME_ANALYSES}/core-metrics-results/unweighted_unifrac_distance_matrix.qza
UW_UF_SAMPLE_TYPE_SIGNIF=${QIIME_ANALYSES}/unweighted_unifrac_distance_matrix_SampleID.qzv
TAXA_BARPLOT=${QIIME_ANALYSES}/taxa_barplot.qzv
ASV_BARPLOT=${QIIME_ANALYSES}/asv_barplots.qzv
## ---------------------------------------------------
## CREATING IMIPORT MANIFEST FILES
# ---------------------------------------------------
# Create a manifest file
# ---------------------------------------------------
LIST_OF_SAMPLES=$( ls ${FASTQS} | grep .fastq.gz | grep -v Undetermined | sed -E 's/_L001_R[1,2]_001.fastq.gz//' | sort | uniq )
READ1_FASTQ_PATHS=$( ls -d ${FASTQS}/* | grep _L001_R1_001.fastq.gz | grep 16S | grep -v Undetermined | sort | uniq )
READ2_FASTQ_PATHS=$( ls -d ${FASTQS}/* | grep _L001_R2_001.fastq.gz | grep 16S | grep -v Undetermined | sort | uniq )
echo -e "sample-id\tforward-absolute-filepath\treverse-absolute-filepath" > $IMPORT_MANIFEST
paste <(echo "$LIST_OF_SAMPLES") <(echo "$READ1_FASTQ_PATHS") <(echo "$READ2_FASTQ_PATHS") | awk '{OFS="\t"} {print $1, $2, $3}' >> $IMPORT_MANIFEST
LINE_COUNT=$( wc -l < "$IMPORT_MANIFEST" )
sed -i 's/trimmed-surviv-pairs-//' $IMPORT_MANIFEST
# Parse out each group for 16S, ITS, and the Mock Communities
# ---------------------------------------------------
echo -e "sample-id\tforward-absolute-filepath\treverse-absolute-filepath" > $THE_16S_IMPORT_MANIFEST
awk 'NR > 1 && /-16S/' $IMPORT_MANIFEST | awk '!/MC1/' >> $THE_16S_IMPORT_MANIFEST
echo -e "sample-id\tforward-absolute-filepath\treverse-absolute-filepath" > $ITS_IMPORT_MANIFEST
awk 'NR > 1 && /-ITS/' $IMPORT_MANIFEST >> $ITS_IMPORT_MANIFEST
echo -e "sample-id\tforward-absolute-filepath\treverse-absolute-filepath" > $MC_IMPORT_MANIFEST
awk 'NR > 1 && /MC1/' $IMPORT_MANIFEST >> $MC_IMPORT_MANIFEST
## Sample metadata files
## ---------------------------------------------------
## I just made these manually in a spreadsheet, saved as a tsv, and copied them to Deoxys
# ---------------------------------------------------
# CREATING QIIME2 ARTIFACTS
# ---------------------------------------------------
[ ! -d ${QIIME_DATA} ] && mkdir -m 755 ${QIIME_DATA}
# Import the data in Qiime2 and create an artifact
# ---------------------------------------------------
for FILE in "${QIIME_DATA}"/qiime_import_manifest_PairedEndFastqManifestPhred33V2_*.tsv; do
    if [[ -f "$FILE" ]]; then
        QZA_OUTPUT=$(basename "$FILE" | sed 's/qiime_import_manifest_PairedEndFastqManifestPhred33V2_//;s/\.tsv//')
        qiime tools import \
          --type 'SampleData[PairedEndSequencesWithQuality]' \
          --input-format PairedEndFastqManifestPhred33V2 \
          --input-path "$FILE" \
          --output-path "${QIIME_DATA}/import_qza_${QZA_OUTPUT}.qza"
    else
        echo "The import manifests aren't being properly recognized and this isn't quite working right just yet"
    fi
done
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-format PairedEndFastqManifestPhred33V2 \
  --input-path $THE_16S_IMPORT_MANIFEST \
  --output-path $THE_16S_IMPORT_QZA
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-format PairedEndFastqManifestPhred33V2 \
  --input-path $ITS_IMPORT_MANIFEST \
  --output-path $ITS_IMPORT_QZA
#[ -r $IMPORT_QZA ] && echo "Dataset imported and Qiime artifact successfully generated"
## ---------------------------------------------------
## ASSIGN TRIMMING PARAMETERS AND GENERATE FEATURE TABLE
## ---------------------------------------------------
## Before carrying this out, be sure to review the fastqc results and determine a trim length for the dataset
#echo "Sit back, this next step may take a little while (~10 min +/-10 min)"
#qiime dada2 denoise-paired \
#    --i-demultiplexed-seqs $IMPORT_QZA \
#    --p-trim-left-f 0 \
#    --p-trim-left-r 0 \
#    --p-trunc-len-f 250 \
#    --p-trunc-len-r 250 \
#    --o-representative-sequences $REP_SEQS_QZA \
#    --o-table $FEATURE_TABLE \
#    --o-denoising-stats $REP_SEQS_STATS \
#    --p-n-threads 16
#qiime metadata tabulate \
#    --m-input-file $REP_SEQS_STATS \
#    --o-visualization $STATS_VIS
#[ -r $STATS_VIS ] && echo "Dereplicated sequences, feature table, merged pairs, and clustered features artifacts have been generated. Check your Qiime visualizations for metrics of your results"
## ---------------------------------------------------
## GENERATE FEATURE TABLE SUMMARIES
## ---------------------------------------------------
#qiime feature-table summarize \
#    --i-table $FEATURE_TABLE \
#    --o-visualization $FEATURE_TABLE_VIS
#qiime feature-table tabulate-seqs \
#    --i-data $REP_SEQS_QZA \
#    --o-visualization $REP_SEQS_QZV
## ---------------------------------------------------
## GENERATE PHYLOGENETIC TREE FOR DIVERSITY ANALYSIS
## ---------------------------------------------------
#qiime phylogeny align-to-tree-mafft-fasttree \
#    --i-sequences $REP_SEQS_QZA \
#    --o-alignment $MSA_QZA \
#    --o-masked-alignment $MSA_MASKED_QZA \
#    --o-tree $UNROOTED_TREE \
#    --o-rooted-tree $ROOTED_TREE
## ---------------------------------------------------
## RAREFACTION ANALYSIS (ALPHA DIVERSITY)
## ---------------------------------------------------
#[ ! -d ${QIIME_ANALYSES} ] && mkdir -m 755 ${QIIME_ANALYSES}
#qiime diversity core-metrics-phylogenetic \
#    --i-phylogeny $ROOTED_TREE \
#    --i-table $FEATURE_TABLE \
#    --p-sampling-depth 350 \
#    --m-metadata-file $SAMPLE_METADATA \
#    --output-dir ${QIIME_ANALYSES}/core-metrics-results # HEADS-UP: Qiime2 will generate this folder itself. You can't path to an existing folder, Qiime will state the folder already exists and it will not overwrite. It'll then give errors that no --output-dir was provided
#qiime diversity alpha-group-significance \
#    --i-alpha-diversity $FAITH_PD_VECTOR \
#    --m-metadata-file $SAMPLE_METADATA \
#    --o-visualization $FAITH_PD_GROUP_SIGNIF_VIS
#qiime diversity alpha-group-significance \
#    --i-alpha-diversity $SHANNON_VECTOR \
#    --m-metadata-file $SAMPLE_METADATA \
#    --o-visualization $SHANNON_GROUP_SIGNIF_VIS
## ---------------------------------------------------
## RAREFACTION PLOTTING (i.e., GENERATING VISUALIZATIONS OF ALPHA DIVERSITY)
## ---------------------------------------------------
#qiime diversity alpha-rarefaction \
#    --i-table $FEATURE_TABLE \
#    --i-phylogeny $ROOTED_TREE \
#    --p-max-depth 4000 \
#    --m-metadata-file $SAMPLE_METADATA \
#    --o-visualization $ALPHA_RAREFACTION
## ---------------------------------------------------
## VISUALIZING BETA DIVERSITY
## ---------------------------------------------------
#qiime diversity beta-group-significance \
#    --i-distance-matrix $UW_UF_DIST_MAT \
#    --m-metadata-file $SAMPLE_METADATA \
#    --m-metadata-column 'Sample_Type' \
#    --o-visualization $UW_UF_SAMPLE_TYPE_SIGNIF
## ---------------------------------------------------
## TAXONOMIC ASSIGNMENT
## ---------------------------------------------------
#qiime feature-classifier classify-sklearn \
#    --i-classifier $TAXONOMY_CLASSIFER \
#    --i-reads $REP_SEQS_QZA \
#    --o-classification $TAXONOMY_QZA
#qiime metadata tabulate \
#    --m-input-file $TAXONOMY_QZA \
#    --o-visualization $TAXONOMY_QZV
## ---------------------------------------------------
## VISUALIZING PROPORTIONS OF ASV AND TAXONOMIC MAKE UP FOR EACH SAMPLE 
## ---------------------------------------------------
#qiime taxa barplot \
#    --i-table $FEATURE_TABLE \
#    --i-taxonomy $TAXONOMY_QZA \
#    --m-metadata-file $SAMPLE_METADATA \
#    --o-visualization $TAXA_BARPLOT
#qiime taxa barplot \
#    --i-table $FEATURE_TABLE \
#    --m-metadata-file $SAMPLE_METADATA \
#    --o-visualization $ASV_BARPLOT
#[ -r $ASV_BARPLOT ] && echo "Script completed. Check out all your artefacts and visualizations, see how they look!"