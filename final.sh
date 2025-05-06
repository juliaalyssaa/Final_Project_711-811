#! /usr/bin/bash

date
source activate qiime2-amplicon-2024.5

homedir="/home/users/kgr1020/GEN711FinalProject"
maindir="/home/users/kgr1020/GEN711FinalProject/Final_Project_711-811"
rddir="$maindir/rawdata" # used to store metadata.tsv and manifest.tsv
demux="/home/users/kgr1020/GEN711FinalProject/demux.files" # files too large to store on github
datadir="$maindir/qiime2.microbiomedata"
mkdir -p $datadir $demux
cd $datadir

# === Step 1: Import data into qiime2 for analysis ===

echo "importing sequences into qiime..."
qiime tools import \
 --type 'SampleData[PairedEndSequencesWithQuality]' \
 --input-path $rddir/manifest.tsv \
 --output-path $demux/demux.qza \
 --input-format PairedEndFastqManifestPhred33V2

echo "converting to qzv file..."
qiime demux summarize \
 --i-data $demux/demux.qza \
 --o-visualization $demux/demux.qzv

# === Step 2: Complete upstream analysis of data (quality control, feature table construction, filtering, taxonomic classification)   ===

# Directories for all upstream analysis outputs and denoised data outputs
usdir="$datadir/upstream.analysis"
denoised="$usdir/denoised.data"
mkdir -p $usdir $denoised
cd $usdir

# Denoising data based on demux.qzv: Forward read quality drops at sequence base 226 and reverse read quality drops at sequence base 200.
echo "filtering reads..."
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs $demux/demux.qza \
  --p-trunc-len-f 220 \
  --p-trunc-len-r 200 \
  --p-n-threads 8 \
  --o-representative-sequences $denoised/asv-seqs.qza \
  --o-table $denoised/asv-table.qza \
  --o-denoising-stats $denoised/stats.qza

# Generating a QIIME2 visualization of denoised data to inspect quality
echo "visualizing metadata stats..."
qiime metadata tabulate \
   --m-input-file $denoised/stats.qza \
   --o-visualization $denoised/stats.qzv

# Exporting asv representative sequences into BLAST-able file
export="$maindir/exported-rep-seqs" 
mkdir -p $export
qiime tools export \
   --input-path $denoised/asv-seqs.qza \
   --output-path $export

# Directories for filtered data analysis outputs
filtreads="$usdir/filtered.reads"
filtfeat="$usdir/filtered.features"
mkdir -p $filtreads $filtfeat

# Removing poor quality samples based on stats.qzv: Sample ODR-3-3 lacks read count. Any samples with less than 1000 reads removed from dataset. 
echo "removing sample ODR-3-3"
qiime feature-table filter-samples \
   --i-table $denoised/asv-table.qza \
   --p-min-frequency 1000 \
   --o-filtered-table $filtreads/asv-filtered-table.qza

# Summarizing the filtered ASV feature table with metadata information for further analysis
echo "performing feature-table summarize action..."
qiime feature-table summarize-plus \
  --i-table $filtreads/asv-filtered-table.qza \
  --m-metadata-file $rddir/metadata.tsv \
  --o-summary $filtreads/asv-table.qzv \
  --o-sample-frequencies $filtreads/sample-frequencies.qza \
  --o-feature-frequencies $filtreads/asv-frequencies.qza

# Compiled table created of all ASV sequences with frequency data.
echo "performing tabulate-seqs action..."
qiime feature-table tabulate-seqs \
  --i-data $denoised/asv-seqs.qza \
  --m-metadata-file $filtreads/asv-frequencies.qza \
  --o-visualization $filtreads/asv-seqs.qzv

# Filtering feature table: all features must be present in 25% of samples.
echo "filtering feature table..."
qiime feature-table filter-features \
  --i-table $filtreads/asv-filtered-table.qza \
  --p-min-samples 5 \
  --o-filtered-table $filtfeat/asv-table-ms5.qza

# Filtering representative ASV sequences to match those relevant and in the feature table
echo "filtering sequences..."
qiime feature-table filter-seqs \
  --i-data $denoised/asv-seqs.qza \
  --i-table $filtfeat/asv-table-ms5.qza \
  --o-filtered-data $filtfeat/asv-seqs-ms5.qza

# Summarizing filtered feature table with metadata information
echo "summarizing feature tables..."
qiime feature-table summarize-plus \
  --i-table $filtfeat/asv-table-ms5.qza \
  --m-metadata-file $rddir/metadata.tsv \
  --o-summary $filtfeat/asv-table-ms5.qzv \
  --o-sample-frequencies $filtfeat/sample-frequencies-ms5.qza \
  --o-feature-frequencies $filtfeat/asv-frequencies-ms5.qza

# Directory for all downloaded tools used during analysis of data
tools="$homedir/tools"
mkdir $tools

# Downloaded and training classifier for taxonomic classification of data based on 16sRNA data with amplified V4 region
classifier="$tools/silva-CUSTOM.qza" #variable for custom trained classifier

echo "training classifier..."
wget -O silva-138-99-seqs.qza https://data.qiime2.org/2024.2/common/silva-138-99-seqs.qza
wget -O silva-138-99-tax.qza https://data.qiime2.org/2024.2/common/silva-138-99-tax.qza

qiime feature-classifier extract-reads \
  --i-sequences silva-138-99-seqs.qza \
  --p-f-primer GTGCCAGCMGCCGCGGTAA \
  --p-r-primer GGACTACHVGGGTWTCTAAT \
  --p-trunc-len 250 \
  --o-reads silva-refseqs-515-806.qza

qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads silva-refseqs-515-806.qza \
  --i-reference-taxonomy silva-138-99-tax.qza \
  --o-classifier $classifier

# For-Do-Done loop for organizing downloaded classifiers into the tools directory
for item in $(ls $usdir)
do
   if [[ $item == silva* ]]
   then
      echo "moving file"
      mv $item $tools
   fi
done

# Directory for storing taxonomic classification of sequences and phylogenetic tree
tdir="$usdir/taxonomic.classification"
tree="$usdir/phylogenetic.tree"
mkdir -p $tdir

# Assigning taxonomy to samples using custom silva classifier
echo "assigning taxonomy to sequences..."
qiime feature-classifier classify-sklearn \
  --i-classifier $classifier \
  --i-reads $filtfeat/asv-seqs-ms5.qza \
  --o-classification $tdir/taxonomy.qza

# Visualizing ASV sequences with taxonomic classifications
echo "visualizing ASV sequences with taxonomic classifications..."
qiime feature-table tabulate-seqs \
   --i-data $filtfeat/asv-seqs-ms5.qza \
   --i-taxonomy $tdir/taxonomy.qza \
   --m-metadata-file $filtfeat/asv-frequencies-ms5.qza \
   --o-visualization $tdir/taxonomy-classification.qzv

# Generating rooted phylogenetic tree from ASV sequences using MAFFT and FastTree for alignment and tree construction. Upload rooted_tree.qza and taxonomy.qza into iTOL for phylogenetic tree.
tree="$usdir/phylogenetic.tree"

echo "constructing phylogenetic tree..."
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences $filtfeat/asv-seqs-ms5.qza \
  --output-dir $tree

# === Step 3: Complete downstream analysis (alpha and beta diversity analysis) ===

# Directories for all downstream analysis outputs and diversity testing outputs
dsdir="$datadir/downstream.analysis"
kmers="$dsdir/diversity.testing"
divres="$dsdir/diversity.results"
mkdir $dsdir $divres
cd $dsdir

# Creating conda environment for QIIME2 boots commands
echo "downloading qiime2 boots environment..."
conda env create \
   --name q2-boots-amplicon-2025.4 \
   --file https://raw.githubusercontent.com/caporaso-lab/q2-boots/refs/heads/main/environment-files/q2-boots-qiime2-amplicon-2025.4.yml

conda activate q2-boots-amplicon-2025.4

# Performing k-mer based diversity analysis, creating 10 bootstrapped rarefied samples with sampling depth of 1200.
qiime boots kmer-diversity \
  --i-table $filtfeat/asv-table-ms5.qza \
  --i-sequences $filtfeat/asv-seqs-ms5.qza \
  --m-metadata-file $rddir/metadata.tsv \
  --p-sampling-depth 1200 \
  --p-n 10 \
  --p-replacement \
  --p-alpha-average-method median \
  --p-beta-average-method medoid \
  --output-dir $kmers

# Generating alpha-rarefaction plot for diversity analysis
echo "creating alpha-rarefaction plot..."
qiime diversity alpha-rarefaction \
  --i-table $filtfeat/asv-table-ms5.qza \
  --p-max-depth 4500 \
  --m-metadata-file $rddir/metadata.tsv \
  --o-visualization $divres/alpha-rarefaction.qzv

# Generating a taxonomic barplot to view the abundance of species within samples
echo "creating taxonomic barplot..."
qiime taxa barplot \
  --i-table $filtfeat/asv-table-ms5.qza \
  --i-taxonomy $tdir/taxonomy.qza \
  --m-metadata-file $rddir/metadata.tsv \
  --o-visualization $divres/taxa-bar-plots.qzv

# Directory for differential abundance testing outputs
diffabun="$dsdir/differential.abundance"
mkdir -p $diffabun

# Filtering the metadata table to focus on comparison between duckweed and water sample groups for further species abundance analysis
echo "filtering metadata table..."
qiime feature-table filter-samples \
  --i-table $filtfeat/asv-table-ms5.qza \
  --m-metadata-file $rddir/metadata.tsv \
  --p-where 'sample_type IN ("duckweed", "water")' \
  --o-filtered-table $diffabun/asv-table-ms5-dominant-sample-types.qza

# Collapsing ASVs into species-level taxonomy (level 7) based on previously provided taxonomic classification
echo "collapsing ASVs into species..."
qiime taxa collapse \
  --i-table $diffabun/asv-table-ms5-dominant-sample-types.qza \
  --i-taxonomy $tdir/taxonomy.qza \
  --p-level 7 \
  --o-collapsed-table $diffabun/genus-table-ms5-dominant-sample-types.qza

# Performing differential abundance testing using ANCOM-BC to identify species-level taxa that are signficantly different between sample types
echo "testing differentially abundance across species..."
qiime composition ancombc \
  --i-table $diffabun/genus-table-ms5-dominant-sample-types.qza \
  --m-metadata-file $rddir/metadata.tsv \
  --p-formula sample_type \
  --p-reference-levels 'sample_type::duckweed' \
  --o-differentials $diffabun/genus-ancombc.qza

# Visualizing the results of differential abundance analysis using a signficance threshold of 0.001
echo "visualizing differential abundance results..."
qiime composition da-barplot \
  --i-data $diffabun/genus-ancombc.qza \
  --p-significance-threshold 0.001 \
  --p-level-delimiter ';' \
  --o-visualization $diffabun/genus-ancombc.qzv

# === Final Step: Log Completion ===
date

echo "pipeline completed"

