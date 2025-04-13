#! /usr/bin/bash

maindir="/home/users/kgr1020/GEN711FinalProject"
datadir="$maindir/qiime2.microbiomedata"
usdir="$datadir/upstream.analysis"
rddir="$maindir/Final_Project_711-811/rawdata"
qzvdir="$usdir/qzvresults"
fdir="$usdir/filteredresults"
tdir="$usdir/taxonomyresults"

#files used: /tmp/qiimme2_dataset/manifest.tsv + metadata.tsv

date

source activate qiime2-amplicon-2024.5

#mkdir -p $datadir
cd $usdir
#mkdir -p $usdir

#echo "importing sequences into qiime..."
#qiime tools import \
# --type 'SampleData[PairedEndSequencesWithQuality]' \
# --input-path $rddir/manifest.tsv \
# --output-path demux.qza \
# --input-format PairedEndFastqManifestPhred33V2

#echo "converting to qzv file..."
#qiime demux summarize \
# --i-data demux.qza \
# --o-visualization $usdir/demux.qzv

#forward read quality drops at sequence base 226 and reverse read quality drops at sequence base 200
#echo "filtering reads..."
#qiime dada2 denoise-paired \
#  --i-demultiplexed-seqs demux.qza \
#  --p-trunc-len-f 220 \
#  --p-trunc-len-r 200 \
#  --p-n-threads 8 \
#  --o-representative-sequences $usdir/asv-seqs.qza \
#  --o-table $usdir/asv-table.qza \
#  --o-denoising-stats $usdir/stats.qza

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
#  --o-sample-frequencies $usdir/sample-frequencies.qza \
#  --o-feature-frequencies $usdir/asv-frequencies.qza

#echo "performing tabulate-seqs action..."
#qiime feature-table tabulate-seqs \
#  --i-data asv-seqs.qza \
#  --m-metadata-file asv-frequencies.qza \
#  --o-visualization $qzvdir/asv-seqs.qzv

#mkdir -p $fdir

#could make into p-min3 or maybe 4
#echo "filtering feature table..."
#qiime feature-table filter-features \
#  --i-table asv-table.qza \
#  --p-min-samples 2 \
#  --o-filtered-table $fdir/asv-table-ms2.qza

#echo "filtering sequences..."
#qiime feature-table filter-seqs \
#  --i-data asv-seqs.qza \
#  --i-table $fdir/asv-table-ms2.qza \
#  --o-filtered-data $fdir/asv-seqs-ms2.qza

fqzvdir="$fdir/qzvresults.filtered"
#mkdir -p $fqzvdir

#echo "summarizing feature tables..."
#qiime feature-table summarize-plus \
#  --i-table $fdir/asv-table-ms2.qza \
#  --m-metadata-file $rddir/metadata.tsv \
#  --o-summary $fqzvdir/asv-table-ms2.qzv \
#  --o-sample-frequencies $fdir/sample-frequencies-ms2.qza \
#  --o-feature-frequencies $fdir/asv-frequencies-ms2.qza

#wget -O 'suboptimal-16S-rRNA-classifier.qza' \
#  'https://gut-to-soil-tutorial.readthedocs.io/en/latest/data/gut-to-soil/suboptimal-16S-rRNA-classifier.qza'

# mkdir -p $tdir

#echo "assigning taxonomy to sequences..."
#qiime feature-classifier classify-sklearn \
#  --i-classifier suboptimal-16S-rRNA-classifier.qza \
#  --i-reads $fdir/asv-seqs-ms2.qza \
#  --o-classification $tdir/taxonomy.qza

#echo "visualizing ASV sequences with taxonomic information..."
#qiime feature-table tabulate-seqs \
#   --i-data $fdir/asv-seqs-ms2.qza \
#   --i-taxonomy $tdir/taxonomy.qza/ \
#   --m-metadata-file $fdir/asv-frequencies-ms2.qza \
#   --o-visualization $tdir/asv-seqs-ms2.qzv

date
