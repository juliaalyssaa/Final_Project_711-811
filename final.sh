#! /usr/bin/bash

maindir="/home/users/kgr1020/GEN711FinalProject"
datadir="$maindir/qiime2.microbiomedata"
dadadir="$datadir/dada2results"
rddir="$maindir/Final_Project_711-811/rawdata"
qzvdir="$dadadir/qzvresults"
fdir="$dadadir/filteredresults"

#files used: /tmp/qiimme2_dataset/manifest.tsv + metadata.tsv

date

source activate qiime2-amplicon-2024.5

#mkdir -p $datadir
cd $datadir
#mkdir -p $dadadir

#echo "importing sequences into qiime..."
#qiime tools import \
# --type 'SampleData[PairedEndSequencesWithQuality]' \
# --input-path $rddir/manifest.tsv \
# --output-path demux.qza \
# --input-format PairedEndFastqManifestPhred33V2

#echo "converting to qzv file..."
#qiime demux summarize \
# --i-data demux.qza \
# --o-visualization $datadir/demux.qzv

#forward read quality drops at sequence base 226 and reverse read quality drops at sequence base 200
#echo "filtering reads..."
#qiime dada2 denoise-paired \
#  --i-demultiplexed-seqs demux.qza \
#  --p-trunc-len-f 220 \
#  --p-trunc-len-r 200 \
#  --p-n-threads 8 \
#  --o-representative-sequences $dadadir/asv-seqs.qza \
#  --o-table $dadadir/asv-table.qza \
#  --o-denoising-stats $dadadir/stats.qza

cd $dadadir
#mkdir -p $qzvdir

#echo "visualizing metadata stats..."
#qiime metadata tabulate \
#   --m-input-file stats.qza \
#   --o-visualization $qzvdir/stats.qzv \

#echo "performing feature-table summarize action..."
#qiime feature-table summarize-plus \
#  --i-table asv-table.qza \
#  --m-metadata-file $rddir/metadata.tsv \
#  --o-summary $qzvdir/asv-table.qzv \
#  --o-sample-frequencies $dadadir/sample-frequencies.qza \
#  --o-feature-frequencies $dadadir/asv-frequencies.qza

#echo "performing tabulate-seqs action..."
#qiime feature-table tabulate-seqs \
#  --i-data asv-seqs.qza \
#  --m-metadata-file asv-frequencies.qza \
#  --o-visualization $qzvdir/asv-seqs.qzv

mkdir -p $fdir

#could make into p-min3 or maybe 4
echo "filtering feature table..."
qiime feature-table filter-features \
  --i-table asv-table.qza \
  --p-min-samples 2 \
  --o-filtered-table $fdir/asv-table-ms2.qza

echo "filtering sequences..."
qiime feature-table filter-seqs \
  --i-data asv-seqs.qza \
  --i-table $fdir/asv-table-ms2.qza \
  --o-filtered-data $fdir/asv-seqs-ms2.qza

date
