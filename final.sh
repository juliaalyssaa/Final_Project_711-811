#! /usr/bin/bash
maindir="/home/users/kgr1020/GEN711FinalProject"
datadir="$maindir/qiime2.microbiomedata"
rddir="$maindir/Final_Project_711-811/rawdata/manifest.tsv"

#files used: /tmp/qiimme2_dataset/manifest.tsv + metadata.tsv

date

source activate qiime2-amplicon-2024.5

mkdir -p $datadir
cd $datadir

echo "importing sequences into qiime"
qiime tools import \
 --type 'SampleData[PairedEndSequencesWithQuality]' \
 --input-path $rddir \
 --output-path demux.qza \
 --input-format PairedEndFastqManifestPhred33V2

echo "converting to qzv file"
qiime demux summarize \
 --i-data demux.qza \
 --o-visualization $datadir/demux.qzv

echo "filtering reads"
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux.qza \
  --p-trim-left-f 0 \
  --p-trunc-len-f 250 \
  --p-trim-left-r 0 \
  --p-trunc-len-r 250 \
  --o-representative-sequences asv-seqs.qza \
  --o-table asv-table.qza \
  --o-denoising-stats stats.qza

echo "performing feature-table summarize action"
qiime feature-table summarize-plus \
  --i-table asv-table.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-summary asv-table.qzv \
  --o-sample-frequencies sample-frequencies.qza \
  --o-feature-frequencies asv-frequencies.qza

echo "performing tabulate-seqs action"
qiime feature-table tabulate-seqs \
  --i-data asv-seqs.qza \
  --m-metadata-file asv-frequencies.qza \
  --o-visualization asv-seqs.qzv

#qiime feature-table filter-features \
#  --i-table asv-table.qza \
#  --p-min-samples 2 \
#  --o-filtered-table asv-table-ms2.qza

#qiime feature-table filter-seqs \
#  --i-data asv-seqs.qza \
#  --i-table asv-table-ms2.qza \
#  --o-filtered-data asv-seqs-ms2.qza
