#! /usr/bin/bash


#files used: /tmp/qiimme2_dataset/manifest.tsv + metadata.tsv
#date

source activate qiime2-amplicon-2024.5

mkdir -p ~/data/{data,results,scripts,visualizations,asv_tables}
cd ~/data

qiime tools import \
 --type 'SampleData[PairedEndSequencesWithQuality]' \
 --input-path /home/users/kgr1020/Final_Project_711-811/data/manifest.tsv \
 --output-path demux.qza \
 --input-format PairedEndFastqManifestPhred33V2

qiime demux summarize \
 --i-data demux.qza \
 --o-visualization demux.qzv

#qiime dada2 denoise-paired \
 # --i-demultiplexed-seqs demux.qza \
  #--p-trim-left-f 0 \
  #--p-trunc-len-f 250 \
  #--p-trim-left-r 0 \
  #--p-trunc-len-r 250 \
  #--o-representative-sequences asv-seqs.qza \
  #--o-table asv-table.qza \
  #--o-denoising-stats stats.qza


