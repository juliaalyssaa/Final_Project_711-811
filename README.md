# Final_Project_711/811
# Duckweed Microbiome QIIME2 Project

The goal of this project is to analyze 16S rRNA sequencing data from microbiome samples associated with duckweed. The aim is to compare and identify the differences in microbial communities between duckweed surfaces and surrounding pond water using QIIME2.

## Group Members
- Julia Murray
- Kayla Royce

<details>
  <summary><strong>Project Overview</strong></summary>
This bioinformatic pipeline utilizes data from two sampling locations, each consisting of two treatments, being duckweed surface microbiome and pond water microbiome. Five replicates were performed per treatment/location. The data consisted of 40 FASTQ files with 20 paired-end read samples, each being 250 base pairs long. The 16srRNA sequence were amplified via Illumina HiSeq 2500 format.


The pipeline was created following the QIIME2 "Gut-to-Soil Axis Tutorial", with the goal of classifiying and analyzing microbial taxonomy between sample types and the differences in microbial abundance. 

The final presentation can be found following this link: 


_all code used for the pipeline can be found under "final.sh" and data results can be found in their respective folders in the repo_


</details>

<details>
  <summary><strong>Methods</strong></summary>

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
  <summary><strong>Results</strong></summary>

  <details>
    <summary>Denoising Plot</summary>

    ![Denoising Plot](https://raw.githubusercontent.com/kaylaroyce/Final_Project_711-811/main/images/DenoiseResults.png)

  </details>

  <details>
    <summary>Alpha-Rarefaction Plot</summary>

    ![Alpha-Rarefaction 1](/images/Alphararefaction.plot1.png)
    ![Alpha-Rarefaction 2](/images/Alphararefaction.plot2.png)
  </details>

  <details>
    <summary>Diversity Analysis</summary>

    ![Diversity 1](/images/PCA.shannonvbraycurtis.svg) 
    ![Diversity 2](/images/PCA.jaccardvfeatures.svg)

  </details>

  <details>
    <summary>Taxonomic Bar Plot</summary>

    ![Taxonomic Bar Plot](/images/TaxonomicBarPlot.Bars.svg)
    ![Taxonomic Bar Plot Key](/images/TaxonomicBarPlot.Key.svg)
  </details>

  <details>
    <summary>Phylogenetic Tree</summary>

    ![Tree 1](/images/PhylogeneticTreewithKey.png)

  </details>

  <details>
    <summary>Differential Abundance</summary>

    ![Differential Abundance](/images/DiffAbundance.ANCOMBC.png)

  </details>

</details>

