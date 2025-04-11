#! /usr/bin/bash

#files used: /tmp/qiimme2_dataset/manifest.tsv + metadata.tsv
qimme tools import \
 --type 'SampleData[PairedEndSequencesWithQuality]' \
 --input-path /home/users/kgr1020/Final_Project_711-811/data/manifest.tsv \
 --output-path demux.qza \
 --input-format PairedEndFastqManifestPhred33V2

qiime demux summarize 
