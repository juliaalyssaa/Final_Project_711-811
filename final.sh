#! /usr/bin/bash

maindir="/home/users/kgr1020/GEN711FinalProject"
rddir="$maindir/Final_Project_711-811/rawdata"
#files used for analysis: /tmp/qiimme2_dataset/manifest.tsv AND /tmp/qiime2_dataset/metadata.tsv

date

source activate qiime2-amplicon-2024.5

datadir="$maindir/qiime2.microbiomedata"
#mkdir -p $datadir
cd $datadir

# === Step 1: Import data into qiime2 for analysis ===

#echo "importing sequences into qiime..."
#qiime tools import \
# --type 'SampleData[PairedEndSequencesWithQuality]' \
# --input-path $rddir/manifest.tsv \
# --output-path demux.qza \
# --input-format PairedEndFastqManifestPhred33V2

#echo "converting to qzv file..."
#qiime demux summarize \
# --i-data demux.qza \
# --o-visualization demux.qzv

# === Step 2: Complete upstream analysis of data (quality control, feature table construction,filtering)   ===

usdir="$datadir/upstream.analysis"
#mkdir -p $usdir
denoised="$usdir/denoised.data"
#mkdir -p $denoised

#Denoising data based on demux.qzv: Forward read quality drops at sequence base 226 and reverse read quality drops at sequence base 200.
#echo "filtering reads..."
#qiime dada2 denoise-paired \
#  --i-demultiplexed-seqs demux.qza \
#  --p-trunc-len-f 220 \
#  --p-trunc-len-r 200 \
#  --p-n-threads 8 \
#  --o-representative-sequences $denoised/asv-seqs.qza \
#  --o-table $denoised/asv-table.qza \
#  --o-denoising-stats $denoised/stats.qza

cd $usdir

#echo "visualizing metadata stats..."
#qiime metadata tabulate \
#   --m-input-file $denoised/stats.qza \
#   --o-visualization $denoised/stats.qzv

filtreads="$usdir/filtered.reads"
#mkdir -p $filtreads
frqzv="$filtreads/fr.qzv.results"
#mkdir -p $frqzv

#Removing poor quality samples based on stats.qzv: Sample ODR-3-3 lacks read count. Any samples with less than 1000 reads removed from dataset. 
#echo "removing sample ODR-3-3"
#qiime feature-table filter-samples \
#   --i-table $denoised/asv-table.qza \
#   --p-min-frequency 1000 \
#   --o-filtered-table $filtreads/asv-filtered-table.qza

#echo "performing feature-table summarize action..."
#qiime feature-table summarize-plus \
#  --i-table $filtreads/asv-filtered-table.qza \
#  --m-metadata-file $rddir/metadata.tsv \
#  --o-summary $frqzv/asv-table.qzv \
#  --o-sample-frequencies $filtreads/sample-frequencies.qza \
#  --o-feature-frequencies $filtreads/asv-frequencies.qza

#Compiled table created of all ASV sequences with frequency data.
#echo "performing tabulate-seqs action..."
#qiime feature-table tabulate-seqs \
#  --i-data $denoised/asv-seqs.qza \
#  --m-metadata-file $filtreads/asv-frequencies.qza \
#  --o-visualization $frqzv/asv-seqs.qzv

filtfeat="$usdir/filtered.features"
#mkdir -p $fdir
ffqzv="$filtfeat/ff.qzv.results"
#mkdir -p $ffqzv

#Filtering feature table: all features must be present in 50% of samples.
#echo "filtering feature table..."
#qiime feature-table filter-features \
#  --i-table $filtreads/asv-filtered-table.qza \
#  --p-min-samples 10 \
#  --o-filtered-table $filtfeat/asv-table-ms10.qza

#echo "filtering sequences..."
#qiime feature-table filter-seqs \
#  --i-data $denoised/asv-seqs.qza \
#  --i-table $filtfeat/asv-table-ms10.qza \
#  --o-filtered-data $filtfeat/asv-seqs-ms10.qza

#echo "summarizing feature tables..."
#qiime feature-table summarize-plus \
#  --i-table $filtfeat/asv-table-ms10.qza \
#  --m-metadata-file $rddir/metadata.tsv \
#  --o-summary $ffqzv/asv-table-ms10.qzv \
#  --o-sample-frequencies $filtfeat/sample-frequencies-ms10.qza \
#  --o-feature-frequencies $filtfeat/asv-frequencies-ms10.qza

tools="$datadir/tools"
#mkdir $tools
cd $tools

#wget \
#  -O "sepp-refs-gg-13-8.qza" \
#  "https://data.qiime2.org/classifiers/sepp-ref-dbs/sepp-refs-gg-13-8.qza"

# === Step 3: Complete downstream analysis (INCLUDES.....) ===

dsdir="$datadir/downstream.analysis"
#mkdir $dsdir
cd $dsdir

rarefaction="$dsdir/alphararefaction.results"
mkdir -p $rarefaction

#tree_placements for diversity metrics, tree.qza for rarefaction
echo "creating phylogenetic tree..."
qiime fragment-insertion sepp \
   --i-representative-sequences $filtfeat/asv-seqs-ms10.qza \
   --i-reference-database $tools/sepp-refs-gg-13-8.qza \
   --o-tree $rarefaction/tree.qza \
   --o-placements $rarefaction/tree_placements.qza \
   --p-threads 8

echo "performing alpha rarefaction plotting"
qiime diversity alpha-rarefaction \
   --i-table $filtfeat/asv-table-ms10.qza \
   --i-phylogeny $rarefaction/tree.qza \
   --m-metadata-file $rddir/metadata.tsv \
   --o-visualization $rarefaction/alpha-rarefaction.qzv \
   --p-min-depth 500 \
   --p-max-depth 2500


#HERE:        wget -O 'suboptimal-16S-rRNA-classifier.qza' \
#  'https://gut-to-soil-tutorial.readthedocs.io/en/latest/data/gut-to-soil/suboptimal-16S-rRNA-classifier.qza'

tdir="$usdir/taxonomyresults"
# mkdir -p $tdir

#echo "assigning taxonomy to sequences..."
#qiime feature-classifier classify-sklearn \
#  --i-classifier suboptimal-16S-rRNA-classifier.qza \
#  --i-reads $fdir/asv-seqs-ms2.qza \
#  --o-classification $tdir/taxonomy.qza

#echo "visualizing ASV sequences with taxonomic information..."
#qiime metadata tabulate \
#   --m-input-file $tdir/taxonomy.qza \
#   --o-visualization $tdir/taxonomy.qzv
# option 1: qiime feature-table tabulate-seqs \
#   --i-data $fdir/asv-seqs-ms2.qza \
#   --i-taxonomy $tdir/taxonomy.qza/ \
#   --m-metadata-file $fdir/asv-frequencies-ms2.qza \
#   --o-visualization $tdir/asv-seqs-ms2.qzv

date
