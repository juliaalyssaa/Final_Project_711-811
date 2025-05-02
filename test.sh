#! /usr/bin/bash

# === Update Working Directory ===
maindir="/home/users/jam1281/Final_Project_711-811"
rddir="$maindir/rawdata"
datadir="$maindir/qiime2.microbiomedata"
usdir="$datadir/upstream.analysis"
filtreads="$usdir/filtered.reads"
filtfeat="$usdir/filtered.features"
tools="$datadir/tools"
tdir="$usdir/taxonomic.classification"
dsdir="$datadir/downstream.analysis"
diffabun="$dsdir/differential.abundance"
tree="$dsdir/tree"
longitudinal="$dsdir/longitudinal"
export="$rddir/exported-rep-seqs" # Define the export directory here

# Create necessary directories
mkdir -p "$datadir" "$usdir" "$filtreads" "$filtfeat" "$tools" "$tdir" "$dsdir" "$diffabun" "$tree" "$longitudinal" "$export"

# Activate the QIIME2 environment
source activate qiime2-amplicon-2024.5

date

# === Step 1: Import Data ===
echo "Importing sequences into QIIME2..."
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path "$rddir/manifest.tsv" \
  --output-path "$datadir/demux.qza" \
  --input-format PairedEndFastqManifestPhred33V2

echo "Summarizing imported sequences..."
qiime demux summarize \
  --i-data "$datadir/demux.qza" \
  --o-visualization "$datadir/demux.qzv"

# === Step 2: Upstream Analysis ===
echo "Denoising data..."
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs "$datadir/demux.qza" \
  --p-trunc-len-f 220 \
  --p-trunc-len-r 200 \
  --p-n-threads 8 \
  --o-representative-sequences "$usdir/denoised-seqs.qza" \
  --o-table "$usdir/denoised-table.qza" \
  --o-denoising-stats "$usdir/denoising-stats.qza"

# Exporting ASV representative sequences into BLAST file
echo "Exporting ASV representative sequences..."
qiime tools export \
  --input-path "$usdir/denoised-seqs.qza" \
  --output-path "$export"

echo "Summarizing denoising stats..."
qiime metadata tabulate \
  --m-input-file "$usdir/denoising-stats.qza" \
  --o-visualization "$usdir/denoising-stats.qzv"

echo "Filtering low-quality samples (min frequency 1000)..."
qiime feature-table filter-samples \
  --i-table "$usdir/denoised-table.qza" \
  --p-min-frequency 1000 \
  --o-filtered-table "$filtreads/asv-filtered-table.qza"

echo "Performing feature-table summarize action (filtered table)..."
qiime feature-table summarize-plus \
  --i-table "$filtreads/asv-filtered-table.qza" \
  --m-metadata-file "$rddir/metadata.tsv" \
  --o-summary "$filtreads/asv-table.qzv" \
  --o-sample-frequencies "$filtreads/sample-frequencies.qza" \
  --o-feature-frequencies "$filtreads/asv-frequencies.qza"

echo "Performing tabulate-seqs action (denoised sequences)..."
qiime feature-table tabulate-seqs \
  --i-data "$usdir/denoised-seqs.qza" \
  --m-metadata-file "$filtreads/asv-frequencies.qza" \
  --o-visualization "$filtreads/asv-seqs.qzv"

echo "Filtering features present in at least 5 samples..."
qiime feature-table filter-features \
  --i-table "$filtreads/asv-filtered-table.qza" \
  --p-min-samples 5 \
  --o-filtered-table "$filtfeat/asv-table-ms5.qza"

echo "Filtering sequences to match filtered feature table..."
qiime feature-table filter-seqs \
  --i-data "$usdir/denoised-seqs.qza" \
  --i-table "$filtfeat/asv-table-ms5.qza" \
  --o-filtered-data "$filtfeat/asv-seqs-ms5.qza"

echo "Summarizing feature tables (MS5)..."
qiime feature-table summarize-plus \
  --i-table "$filtfeat/asv-table-ms5.qza" \
  --m-metadata-file "$rddir/metadata.tsv" \
  --o-summary "$filtfeat/asv-table-ms5.qzv" \
  --o-sample-frequencies "$filtfeat/sample-frequencies-ms5.qza" \
  --o-feature-frequencies "$filtfeat/asv-frequencies-ms5.qza"

# === Step 3: Taxonomic Classification ===
echo "Training classifier..."
wget -O "$tools/silva-138-99-seqs.qza" https://data.qiime2.org/2024.2/common/silva-138-99-seqs.qza
wget -O "$tools/silva-138-99-tax.qza" https://data.qiime2.org/2024.2/common/silva-138-99-tax.qza

qiime feature-classifier extract-reads \
  --i-sequences "$tools/silva-138-99-seqs.qza" \
  --p-f-primer GTGCCAGCMGCCGCGGTAA \
  --p-r-primer GGACTACHVGGGTWTCTAAT \
  --p-trunc-len 250 \
  --o-reads "$tools/silva-refseqs-515-806.qza"

qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads "$tools/silva-refseqs-515-806.qza" \
  --i-reference-taxonomy "$tools/silva-138-99-tax.qza" \
  --o-classifier "$tools/silva-CUSTOM.qza"

echo "Assigning taxonomy to sequences..."
qiime feature-classifier classify-sklearn \
  --i-reads "$filtfeat/asv-seqs-ms5.qza" \
  --o-classification "$tdir/taxonomy.qza"

echo "Visualizing ASV sequences with taxonomic classifications..."
qiime feature-table tabulate-seqs \
  --i-data "$filtfeat/asv-seqs-ms5.qza" \
  --i-taxonomy "$tdir/taxonomy.qza" \
  --m-metadata-file "$filtfeat/asv-frequencies-ms5.qza" \
  --o-visualization "$tdir/taxonomy-classification.qzv"

# === Step 4: Downstream Analysis ===
echo "Filtering metadata table for duckweed and water samples..."
qiime feature-table filter-samples \
  --i-table "$filtfeat/asv-table-ms5.qza" \
  --m-metadata-file "$rddir/metadata.tsv" \
  --p-where 'sample_type IN ("duckweed", "water")' \
  --o-filtered-table "$diffabun/asv-table-ms5-dominant-sample-types.qza"

echo "Collapsing ASVs into species-level taxonomy..."
qiime taxa collapse \
  --i-table "$diffabun/asv-table-ms5-dominant-sample-types.qza" \
  --i-taxonomy "$tdir/taxonomy.qza" \
  --p-level 7 \
  --o-collapsed-table "$diffabun/genus-table-ms5-dominant-sample-types.qza"

echo "Testing differentially abundance across species..."
qiime composition ancombc \
  --i-table "$diffabun/genus-table-ms5-dominant-sample-types.qza" \
  --m-metadata-file "$rddir/metadata.tsv" \
  --p-formula sample_type \
  --p-reference-levels 'sample_type::duckweed' \
  --o-differentials "$diffabun/genus-ancombc.qza"

echo "Visualizing differential abundance results..."
qiime composition da-barplot \
  --i-data "$diffabun/genus-ancombc.qza" \
  --p-significance-threshold 0.001 \
  --p-level-delimiter ';' \
  --o-visualization "$diffabun/genus-ancombc.qzv"

# === Step 5: Phylogenetic Tree Construction ===
echo "Building phylogenetic tree..."
qiime phylogeny fasttree \
  --i-alignment "$filtfeat/asv-seqs-ms5.qza" # Using filtered sequences
  --o-tree "$tree/unrooted-tree.qza"

echo "Rooting the phylogenetic tree..."
qiime phylogeny midpoint-root \
  --i-tree "$tree/unrooted-tree.qza" \
  --o-rooted-tree "$tree/rooted-tree.qza"

echo "Installing empress..."
pip install empress

echo "Refreshing QIIME 2 cache..."
qiime dev refresh-cache

echo "Adding taxonomic data to the phylogenetic tree (Empress)..."

qiime empress tree-plot \
  --i-tree "$tree/rooted-tree.qza" \
  --m-feature-metadata-file "$tdir/taxonomy.qza" \
  --o-visualization "$tree/empress-tree-tax.qzv"

echo "Adding metadata and taxonomic data to the phylogenetic tree (Empress)..."
qiime empress community-plot \
  --i-tree "$tree/rooted-tree.qza" \
  --i-feature-table "$filtfeat/asv-table-ms5.qza" # Using filtered table
  --m-sample-metadata-file "$rddir/metadata.tsv" \
  --m-feature-metadata-file "$tdir/taxonomy.qza" \
  --o-visualization "$tree/empress-tree-tax-table.qzv"

# === Step 6: Longitudinal Analysis (Requires R) ===
echo "Preparing metadata for longitudinal analysis (R)..."
echo "Running R script to clean metadata..."
Rscript -e "
library(readr)
library(dplyr)

df <- read_tsv('$rddir/metadata.tsv')

df2 <- df %>%
  select(-c('gsrs', 'gsrs-diff', 'administration-route'))

df2[is.na(df2)] <- ''
write_tsv(df2, '$rddir/clean-metadata.tsv', na = '')
"

echo "Filtering feature table (no donor samples)..."
qiime feature-table filter-samples \
  --i-table "$filtfeat/asv-table-ms5.qza" # Using filtered table
  --m-metadata-file "$rddir/clean-metadata.tsv" \
  --p-where \"[treatment-group] IN ('control', 'treatment')\" \
  --o-filtered-table "$longitudinal/no-donor-table.qza"

echo "Collapsing ASVs to genus level for longitudinal analysis..."
qiime taxa collapse \
  --i-table "$longitudinal/no-donor-table.qza" \
  --i-taxonomy "$tdir/taxonomy.qza" \
  --p-level 6 \
  --o-collapsed-table "$longitudinal/no-donor-genus-table.qza"

echo "Converting counts to relative frequencies..."
qiime feature-table relative-frequency \
  --i-table "$longitudinal/no-donor-genus-table.qza" \
  --o-relative-frequency-table "$longitudinal/no-donor-genus-relFreq-table.qza"

echo "Creating longitudinal volatility plot..."
qiime longitudinal volatility \
  --i-table "$longitudinal/no-donor-genus-relFreq-table.qza" \
  --p-state-column week \
  --m-metadata-file "$rddir/clean-metadata.tsv" \
  --p-individual-id-column subject-id \
  --p-default-group-column treatment-group \
  --o-visualization "$longitudinal/volatility-plot.qzv"

# === Final Step: Log Completion ===
date
echo "Pipeline completed successfully!"


