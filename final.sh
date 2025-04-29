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

#FIX maybe where this is located
export="$rddir/exported-rep-seqs"
#mkdir -p $export

#exporting asv representative sequences into BLAST file
#qiime tools export \
#   --input-path $denoised/asv-seqs.qza \
#   --output-path $export

#cd $usdir

#echo "visualizing metadata stats..."
#qiime metadata tabulate \
#   --m-input-file $denoised/stats.qza \
#   --o-visualization $denoised/stats.qzv

filtreads="$usdir/filtered.reads"
#mkdir -p $filtreads

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
#  --o-summary $filtreads/asv-table.qzv \
#  --o-sample-frequencies $filtreads/sample-frequencies.qza \
#  --o-feature-frequencies $filtreads/asv-frequencies.qza

#Compiled table created of all ASV sequences with frequency data.
#echo "performing tabulate-seqs action..."
#qiime feature-table tabulate-seqs \
#  --i-data $denoised/asv-seqs.qza \
#  --m-metadata-file $filtreads/asv-frequencies.qza \
#  --o-visualization $filtreads/asv-seqs.qzv

filtfeat="$usdir/filtered.features"
#mkdir -p $filtfeat

#Filtering feature table: all features must be present in 50% of samples.
#echo "filtering feature table..."
#qiime feature-table filter-features \
#  --i-table $filtreads/asv-filtered-table.qza \
#  --p-min-samples 5 \
#  --o-filtered-table $filtfeat/asv-table-ms5.qza

#echo "filtering sequences..."
#qiime feature-table filter-seqs \
#  --i-data $denoised/asv-seqs.qza \
#  --i-table $filtfeat/asv-table-ms5.qza \
#  --o-filtered-data $filtfeat/asv-seqs-ms5.qza

#echo "summarizing feature tables..."
#qiime feature-table summarize-plus \
#  --i-table $filtfeat/asv-table-ms5.qza \
#  --m-metadata-file $rddir/metadata.tsv \
#  --o-summary $filtfeat/asv-table-ms5.qzv \
#  --o-sample-frequencies $filtfeat/sample-frequencies-ms5.qza \
#  --o-feature-frequencies $filtfeat/asv-frequencies-ms5.qza

tools="$datadir/tools"
#mkdir $tools

classifier="$tools/silva-CUSTOM.qza"

#echo "training classifier..."
#wget -O silva-138-99-seqs.qza https://data.qiime2.org/2024.2/common/silva-138-99-seqs.qza
#wget -O silva-138-99-tax.qza https://data.qiime2.org/2024.2/common/silva-138-99-tax.qza

#qiime feature-classifier extract-reads \
#  --i-sequences silva-138-99-seqs.qza \
#  --p-f-primer GTGCCAGCMGCCGCGGTAA \
#  --p-r-primer GGACTACHVGGGTWTCTAAT \
#  --p-trunc-len 250 \
#  --o-reads silva-refseqs-515-806.qza

#qiime feature-classifier fit-classifier-naive-bayes \
#  --i-reference-reads silva-refseqs-515-806.qza \
#  --i-reference-taxonomy silva-138-99-tax.qza \
#  --o-classifier $classifier

for item in $(ls $datadir)
do
   if [[ $item == silva* ]]
   then
      echo "moving files"
      mv $item $tools
   fi
done

tdir="$usdir/taxonomic.classification"
#mkdir -p $tdir

#echo "assigning taxonomy to sequences..."
#qiime feature-classifier classify-sklearn \
#  --i-classifier $classifier \
#  --i-reads $filtfeat/asv-seqs-ms5.qza \
#  --o-classification $tdir/taxonomy.qza

#echo "visualizing ASV sequences with taxonomic classifications..."
#qiime feature-table tabulate-seqs \
#   --i-data $filtfeat/asv-seqs-ms5.qza \
#   --i-taxonomy $tdir/taxonomy.qza \
#   --m-metadata-file $filtfeat/asv-frequencies-ms5.qza \
#   --o-visualization $tdir/taxonomy-classification.qzv

# === Step 3: Complete downstream analysis (INCLUDES.....) ===

dsdir="$datadir/downstream.analysis"
#mkdir $dsdir
cd $dsdir
kmers="$dsdir/kmer.diversity"

#echo "downloading qiime2 boots environment..."
#conda env create \
#   --name q2-boots-amplicon-2025.4 \
#   --file https://raw.githubusercontent.com/caporaso-lab/q2-boots/refs/heads/main/environment-files/q2-boots-qiime2-amplicon-2025.4.yml

conda activate q2-boots-amplicon-2025.4

#qiime boots kmer-diversity \
#  --i-table $filtfeat/asv-table-ms5.qza \
#  --i-sequences $filtfeat/asv-seqs-ms5.qza \
#  --m-metadata-file $rddir/metadata.tsv \
#  --p-sampling-depth 1200 \
#  --p-n 10 \
#  --p-replacement \
#  --p-alpha-average-method median \
#  --p-beta-average-method medoid \
#  --output-dir $kmers

divres="$dsdir/diversity.results"
#mkdir -p $divres

#echo "creating alpha-rarefaction plot..."
#qiime diversity alpha-rarefaction \
#  --i-table $filtfeat/asv-table-ms5.qza \
#  --p-max-depth 4500 \
#  --m-metadata-file $rddir/metadata.tsv \
#  --o-visualization $divres/alpha-rarefaction.qzv

#echo "creating taxonomic barplot..."
#qiime taxa barplot \
#  --i-table $filtfeat/asv-table-ms5.qza \
#  --i-taxonomy $tdir/taxonomy.qza \
#  --m-metadata-file $rddir/metadata.tsv \
#  --o-visualization $divres/taxa-bar-plots.qzv

date
