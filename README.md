# Final_Project_711/811
# Duckweed Microbiome QIIME2 Project

This project analyzes 16S rRNA sequencing data from microbiome samples associated with duckweed. The aim is to compare microbial communities between duckweed surfaces and surrounding pond water using QIIME2.

## Group Members
- Julia Murray
- Kayla Royce

## Project Overview

We are working with:
- **40 FASTQ files** (20 paired-end samples)
- **Illumina HiSeq 2500**
- **Paired-end, 250 bp reads**

### Sample Design
- **2 Sampling Locations**
- **2 Treatments:**
  - Duckweed surface microbiome
  - Pond water microbiome
- **5 Replicates per treatment/location**

### Files Provided
- `manifest_file.csv`: Tells QIIME2 where each FASTQ file is.
- `metadata.tsv`: Describes treatment, sample ID, location, etc.
