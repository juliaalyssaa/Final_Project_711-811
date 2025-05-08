# Final_Project_711/811
# Duckweed Microbiome QIIME2 Project

The goal of this project is to analyze 16S rRNA sequencing data from microbiome samples associated with duckweed. The aim is to compare and identify the differences in microbial communities between duckweed surfaces and surrounding pond water using QIIME2.

## Group Members
- Julia Murray
- Kayla Royce
<details>
  <summary>## Project Overview</summary>

Data for bioinformatic pathway analysis through qiime2:
- **40 FASTQ files** (20 paired-end samples)
- **16s rRNA data**
- **Illumina HiSeq 2500**
- **Paired-end, 250 bp reads**
</details>
<details>
  <summary>### Methods</summary>

  - **2 Sampling Locations**
- **2 Treatments:**
  - Duckweed surface microbiome
  - Pond water microbiome
- **5 Replicates per treatment/location**
<details>
  <summary>Importing Data</summary>
  Files used: manifest.tsv and metadata.tsv (already demultiplexed)
  imported via: cp from /tmp/ 
</details>
<details>
  <summary>Denoising Preparation</summary>
  Tools used:
  - demux summarize : converts demux.qza into demux.qzv (visualized file)
    - used to determine where to denoise data
</details>
<details>
  <summary>Denoising</summary>
  Tools used:
  - dada2 denoise-paired : used to denoise data
    - forward reads trimmed at 220 bases
    - reverse reads trimmed at 200 bases
  - metadata tabulate : generates QIIME2 visualization of denoised data including feature IDs, sequences, and their counts
    - used to determine where to filter samples
  - tools export : used to export ASV representative sequences into BLAST-able file
</details>
<details>
  <summary>Filtering</summary>
  Tools used:
  - feature-table filter-samples : removes samples with less than 1000 reads and removes sample ODR-3-3 (had 0 reads)
  - feature-table summarize-plus : summarized the filtered ASV feature table with metadata information
  - feature-table tabulate-seqs : creates compiled table of all ASV sequences and their frequency data
  - feature-table filter-features : filters the feature table so all features must be present in a minimum of 25% of the samples
  - feature-table filter-seqs : filters ASV representative sequences to match those in feature table
  - feature-table summarize plus : create visualization of the filtered feature table
</details>
<details>
  <summary>Taxonomic Classification</summary>
  Training Classifier
  Tools used:
  - wget -o silva-138-99-seqs.qza and wget -o silva-138-99-tax.qza
  - feature-classifier extract reads : filters the classifier for primer sequences
    - forward primer: GTGCCAGCMGCCGCGGTAA
    - reverse primer : GGACTACHVGGGTWTCTAAT
  - feature-classifier fit-classifier-naive-bayes : trains custom classifier using previously filtered reference sequences and taxonomic classifier
  Taxonomic Classification
  Tools used:
  - feature-classifier classify-sklearn : assigns taxonomy to samples using the custom trained classifier
  - feature-table tabulate-seqs : visualizes ASV sequences into feature table with taxonomic information
</details>
<details>
  <summary>Phylogenetic Tree Construction</summary>
  Tools used:
  - phylogeny align-to-tree-mafft-fasttree : aligns the features in feature table and creates a rooted tree
  - while loop used to create "itol.txt" : file with node IDs and assigned genus and species
  - "rooted_tree.qza" and "itol.txt" uploaded to iTOL for phylogenetic tree construction
  iTOL: https://itol.embl.de/
</details>
<details>
  <summary>K-mer Based Diversity Analysis</summary>
  Tools used:
  - conda activate q2-boots-amplicon-2025.4 : activates QIIME2 environment with boots kmer-diversity commands
  - boots kmer-diversity : computers kmer based diversity metrics to avoid bias from taxonomic assignment
</details>
<details>
  <summary>Alpha-Rarefaction Plot</summary>
  Tools used:
  - diversity alpha-rarefaction: shows if selected sequencing depth contains majority of the species present
</details>
<details>
  <summary>Taxonomic Bar-Plot</summary>
  Tools used:
  - taxa barplot : shows taxonomic composition and relative abundance for each sample type
</details>
<details>
  <summary>Differential Abundance</summary>
  Tools used:
  - feature-table filter-samples : filters features to compare duckweed and water samples
  - taxa collapse : collapses ASVs into species-level taxonomy (level 7)
  - composition ancombc : performs ANCOM-BC testing to identify signficantly different species-level taxa across sample types
  - composition da-barplot : visualizes results of ANCOM-BC analysis with signficance threshold of 0.001
</details>
</details>

<details>
  <summary>Results</summary>
  <details>
    <summary>Denoising Plot</summary>
    ![image](https://github.com/user-attachments/assets/18a8d6dc-527b-4f45-9df0-ce0cd4822380)
  </details>
  <details>
  <summary>Alpha-Rarefaction Plot</summary>
    ![image](https://github.com/user-attachments/assets/ad03de24-a3ff-4a72-be51-e2675b12d1b0)
  </details>
  <details>
    <summary>Diversity Analysis</summary>
    ![image](https://github.com/user-attachments/assets/3efb22e5-0651-4338-b597-5f7de413cd67)
    ![image](https://github.com/user-attachments/assets/7b1d196a-c8c8-4632-bd9d-2dc7f3933f0d)
  </details>
  <details>
    <summary>Taxonomic Bar Plot</summary>
    ![image](https://github.com/user-attachments/assets/c0b5c6f4-b7f1-433d-b29f-8163fb37e87b)
  </details>
  <details>
    <summary>Phylogenetic Tree</summary>
    ![image](https://github.com/user-attachments/assets/b05f44a5-c592-4aa0-9653-801c7dcff125)
    ![image](https://github.com/user-attachments/assets/6b60f9c2-d50f-4b95-9fd8-a1ae01588398)
  </details>
  <details>
    <summary>Differential Abundance</summary>
    ![image](https://github.com/user-attachments/assets/9b9a8fbe-c30c-45d1-a07d-c4ba6dc24a0e)
  </details>
  
</details>
