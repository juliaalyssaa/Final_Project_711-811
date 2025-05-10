# Microbiome Analysis Pipeline 

<details>
  <summary><b> Script Initialization and Environment Setup</b></summary>

  This section initializes the script by printing the current date and time for logging. It then activates the specified QIIME 2 environment, ensuring that the correct software and dependencies are available for the analysis. Key directory variables are defined for organizing input and output files. The script also takes the home directory as the first argument from the command line, enhancing portability.

  ```bash
  #! /usr/bin/bash

  date
  source activate qiime2-amplicon-2024.5

  home="$1" # first argument in command line should be home directory (example : /home/users/kgr1020)
  homedir="$home/GEN711FinalProject"
  maindir="/home/users/kgr1020/GEN711FinalProject/Final_Project_711-811"
  rddir="$maindir/rawdata" # used to store metadata.tsv and manifest.tsv
  demux="/home/users/kgr1020/GEN711FinalProject/demux.files" # files too large to store on github
  datadir="$maindir/qiime2.microbiomedata"
  mkdir -p $datadir $demux
  cd $datadir
  ```

</details>

<details>
  <summary><b> Step 1: Import Data into QIIME 2</b></summary>

  This step imports the raw sequencing data into QIIME 2 using the `qiime tools import` command. It specifies the data type (`SampleData[PairedEndSequencesWithQuality]`), the path to the manifest file (`$rddir/manifest.tsv`), the output path for the QIIME 2 artifact (`$demux/demux.qza`), and the input format (`PairedEndFastqManifestPhred33V2`). Following import, `qiime demux summarize` generates an initial quality assessment visualization (`.qzv`).

  ```bash
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
  ```

</details>

<details>
  <summary><b> Step 2: Upstream Analysis - Quality Control and Feature Table Construction, Filtering, Taxonomic Classification</b></summary>

  This section initiates the upstream analysis phase, which involves several critical steps for preparing the raw sequencing data. It first defines the primary output directory for all upstream analysis results as $usdir, located within the main QIIME 2 data directory. Subsequently, it creates a specific subdirectory named (`$denoised`) inside (`$usdir`) to house the outputs from the denoising process. The (`mkdir -p`) command ensures that both these directories are created, handling the creation of any necessary parent directories as well. Finally, the script changes the current working directory to $usdir, ensuring that all subsequent commands related to upstream analysis are executed within this designated and organized location.

  ```bash
  # === Step 2: Complete upstream analysis of data (quality control, feature table construction, filte
ring, taxonomic classification)   ===

# Directories for all upstream analysis outputs and denoised data outputs
usdir="$datadir/upstream.analysis"
denoised="$usdir/denoised.data"
mkdir -p $usdir $denoised
cd $usdir
```

</details>

<details>
 <summary><b> Step 2A: Denoise Data and Construct Feature Table</b></summary>

  This part of the script executes the QIIME 2 command (`qiime feature-table tabulate-seqs`). It takes the representative sequences of the identified ASVs from the (`$denoised/asv-seqs.qza`) file and combines them with the frequency information of these ASVs across all samples, which is stored in (`$filtreads/asv-frequencies.qza`). The output is an interactive visualization file named (`$filtreads/asv-seqs.qzv`). This visualization allows users to examine the DNA sequence of each unique microbial variant (ASV) and see its overall abundance within the entire dataset. This step is crucial for understanding the composition of the microbial community and identifying the most prevalent ASVs.

```bash
 # === Step 2A: Denoise data and construct feature tables  ===

# Denoising data based on demux.qzv: Forward read quality drops at sequence base 226 and reverse rea
d quality drops at sequence base 200.
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
```
</details>

<details>
 <summary><b> Step 2B: Filter Features From Data</b></summary>

  This section focuses on filtering the features (ASVs) within the dataset. First, it filters the ASV feature table, retaining only those ASVs that are present in at least 25% of the samples, which is set to a minimum of 5 samples using the (`qiime feature-table filter-features`) command. This step aims to remove rare or potentially spurious ASVs that are not consistently observed across the samples. Next, it filters the representative ASV sequences using (`qiime feature-table filter-seqs`) to ensure that only the sequences corresponding to the ASVs retained in the filtered feature table are kept. This maintains consistency between the sequence data and the feature table used for downstream analysis. Finally, the filtered feature table is summarized using (`qiime feature-table summarize-plus`). This generates visualizations and statistics of the filtered data, including sample and feature frequencies, providing an overview of the dataset after the feature filtering step and allowing for quality checks. The metadata file is included in this summarization to provide context to the sample information.

 ```bash
# === Step 2B: Filter features from data  ===

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
```
</details>

<details>
 <summary><b> Step 2C: Taxonomic Classification</b></summary>
  
  This section focuses on assigning taxonomic identities to the filtered ASV sequences. It first sets up a directory (`$tools`) to store any downloaded software or databases used in the analysis. It then downloads the Silva 138 99% reference sequences and taxonomy files, which are commonly used for 16S rRNA gene classification. To focus the classification on the V4 region of the 16S rRNA gene (the amplified region in the data), the script extracts the relevant reads from the Silva reference database using the specified forward and reverse primers. A Naive Bayes classifier is then trained using these extracted reference reads and their corresponding taxonomy. A loop is included to organize any downloaded Silva-related files by moving them into the (`$tools directory`). Next, directories (`$tdir`) for taxonomic classification results and (`$tree`) for phylogenetic tree files are created. The trained classifier is then used to assign taxonomy to the filtered ASV representative sequences using the classify-sklearn method, and the resulting taxonomic assignments are stored in (`$tdir/taxonomy.qza`). Finally, a visualization is created using qiime (`feature-table tabulate-seqs`) to link the ASV sequences with their assigned taxonomic information and their frequencies, allowing for inspection of the taxonomic composition of the microbial communities.

```bash
# === Step 2C: Taxonomic Classification  ===

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
```
</details>

<details>
 <summary><b> Step 2C: Phylogenetic Tree Construction</b></summary>
  
   This section focuses on constructing a phylogenetic tree to visualize the evolutionary relationships between the identified ASVs. It uses the qiime phylogeny (`align-to-tree-mafft-fasttree command`), which first aligns the filtered ASV sequences using MAFFT and then builds a phylogenetic tree from the alignment using FastTree. The output is a rooted phylogenetic tree. To prepare this tree and the taxonomic information for visualization in iTOL (Interactive Tree Of Life), the script creates a directory (`$tree/iTOL.files`). It then exports the rooted tree, the taxonomic assignments, and the ASV feature table into this directory. The feature table is also converted from the (`.biom`) format to a tab-separated (`.tsv`) file, which is a common format for iTOL. Finally, the script generates a specially formatted text file named (`itol.txt`). This file extracts the genus and species information from the exported taxonomy file and creates labels that can be uploaded into iTOL to display taxonomic information directly on the nodes of the phylogenetic tree, making the tree more informative.

   ```bash
# === Step 2D: Phylogenetic Tree Construction  ===

# Generating rooted phylogenetic tree from ASV sequences using MAFFT and FastTree for alignment and tree construction. Upload rooted_tree.qza and taxonomy.qza into iTOL for phylogenetic tree.
echo "constructing phylogenetic tree..."
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences $filtfeat/asv-seqs-ms5.qza \
  --output-dir $tree

# Creating exported taxonomy.qza, feature-table.qza, and ASV table files for iTOL upload
iTOL="$tree/iTOL.files"

echo "exporting files for use in iTOL..."
qiime tools export \
  --input-path $tree/rooted_tree.qza \
  --output-path $iTOL/exported_tree
qiime tools export \
  --input-path $tdir/taxonomy.qza \
  --output-path $iTOL/exported_taxonomy
qiime tools export \
  --input-path $filtfeat/asv-table-ms5.qza \
  --output-path $iTOL/exported_table

echo "converting feature table into tsv format..."
biom convert \
  -i $iTOL/exported_table/feature-table.biom \
  -o $iTOL/exported_table/feature-table.tsv \
  --to-tsv

# Creating iTOL.txt labels for upload into phylogenetic tree to alter node IDs to genus and species labels
TAXONOMY="$iTOL/exported_taxonomy/taxonomy.tsv"
OUTPUT="$iTOL/itol.txt"

{
echo "LABELS"
echo "SEPARATOR COMMA"
echo ""
echo "DATA"
} > "$OUTPUT"

# Altering each line in the taxnomy file
tail -n +2 "$TAXONOMY" | while IFS=$'\t' read -r asv_id taxonomy _; do
    # Extract genus and species from file
    genus=$(echo "$taxonomy" | grep -o 'g__[^;]*' | sed 's/g__//')
    species=$(echo "$taxonomy" | grep -o 's__[^;]*' | sed 's/s__//')

    # Default/fallback values if no assigned taxonomy
    genus=${genus:-Unassigned}
    species=${species:-sp.}

    echo "$asv_id,$genus $species" >> "$OUTPUT"
done

```
</details>

 <details>
 <summary><b> Step 3: Complete Downstream Analysis (Alpha and Beta Diversity Analysis, Differential Abundance, Plots/Charts)</b></summary>

  This section marks the beginning of the downstream analysis, which aims to interpret the processed microbial data. It encompasses exploring the diversity within (alpha) and between (beta) samples, identifying microbes with significantly different abundances across conditions (differential abundance), and generating various plots and charts to visualize these findings. To organize the outputs of these analyses, the script first defines a main directory (`$dsdir`) for all downstream analysis results, located within the primary QIIME 2 data directory. It then creates two subdirectories within (`$dsdir: $kmers`) specifically for results related to k-mer based diversity testing and (`$divres`) for general diversity analysis results and visualizations. Finally, the script changes the current working directory to (`$dsdir`), ensuring that all subsequent commands related to downstream analysis are executed within this organized location.

  ```bash
# === Step 3: Complete downstream analysis (alpha and beta diversity analysis, differential abundanc
e, plots/charts) ===

# Directories for all downstream analysis outputs and diversity testing outputs
dsdir="$datadir/downstream.analysis"
kmers="$dsdir/diversity.testing"
divres="$dsdir/diversity.results"
mkdir $dsdir $divres
cd $dsdir
```
</details>

<details>
 <summary><b> Step 3A: Diversity Analysis</b></summary>
  
   This section performs diversity analysis, specifically using a k-mer based approach. First, it sets up a dedicated Conda environment named (`q2-boots-amplicon-2025.4`) to ensure the necessary software and dependencies for the (`q2-boots QIIME 2 plugin`) are available. The environment is created using a YAML file downloaded from a specified URL. After creation, this environment is activated. The script then executes the (`qiime boots kmer-diversity`) command, which performs k-mer based diversity analysis. This analysis involves creating 10 bootstrapped, rarefied versions of the data, each rarefied to a sampling depth of 1200 reads. The alpha and beta diversity metrics are then calculated from these bootstrapped samples. The median is used to average the alpha diversity values, and the medoid is used to average the beta diversity distance matrices. The results of this analysis are stored in the (`$kmers`) directory.

```bash
# === Step 3A: Diversity Analysis  ===

# Creating conda environment for QIIME2 boots commands
echo "downloading qiime2 boots environment..."
conda env create \
   --name q2-boots-amplicon-2025.4 \
   --file https://raw.githubusercontent.com/caporaso-lab/q2-boots/refs/heads/main/environment-files/
q2-boots-qiime2-amplicon-2025.4.yml

conda activate q2-boots-amplicon-2025.4

# Performing k-mer based diversity analysis, creating 10 bootstrapped rarefied samples with sampling
 depth of 1200.
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
```
</details>

<details>
 <summary><b> Step 3B: Alpha-rarefaction Plotting</b></summary>
  
   This section focuses on generating an alpha-rarefaction plot. The script uses the qiime diversity alpha-rarefaction command to create a visualization that helps assess whether the sequencing depth was sufficient to capture the microbial diversity within the samples. The command takes the filtered ASV feature table as input and calculates alpha diversity metrics at various sequencing depths, up to a maximum depth of 4500 reads. The metadata file is also provided, allowing for potential coloring or grouping of the rarefaction curves based on sample metadata. The resulting interactive plot, saved as (`$divres/alpha-rarefaction.qzv`), shows how alpha diversity changes with increasing sequencing effort, indicating if the diversity estimates have plateaued.

   ```bash
   # === Step 3B: Alpha-rarefaction Plotting  ===

# Generating alpha-rarefaction plot for diversity analysis
echo "creating alpha-rarefaction plot..."
qiime diversity alpha-rarefaction \
  --i-table $filtfeat/asv-table-ms5.qza \
  --p-max-depth 4500 \
  --m-metadata-file $rddir/metadata.tsv \
  --o-visualization $divres/alpha-rarefaction.qzv
  ```

</details>

<details>
 <summary><b> Step 3C: Taxonomic Barplot Construction</b></summary>
  
  This section generates a taxonomic barplot to visualize the relative abundance of different microbial taxa across the samples. The script uses the qiime taxa barplot command, taking the filtered ASV feature table and the taxonomic assignments as input. The metadata file is also included, which allows for ordering or grouping of the samples in the barplot based on metadata categories. The resulting interactive barplot, saved as (`$divres/taxa-bar-plots.qzv`), displays the proportion of each taxon within each sample, providing a visual overview of the community composition. While the comment mentions "species," the barplot can typically display taxa at various taxonomic levels depending on how it's explored in the resulting visualization.

  ```bash
# === Step 3C: Taxonomic Barplot Construction  ===

# Generating a taxonomic barplot to view the abundance of species within samples
echo "creating taxonomic barplot..."
qiime taxa barplot \
  --i-table $filtfeat/asv-table-ms5.qza \
  --i-taxonomy $tdir/taxonomy.qza \
  --m-metadata-file $rddir/metadata.tsv \
  --o-visualization $divres/taxa-bar-plots.qzv
```

</details>

<details>
 <summary><b> Step 3D: Differential Abundance Testing</b></summary>

  This section performs differential abundance testing to identify microbial taxa whose abundance differs significantly between sample groups. It begins by visualizing and statistically testing for differences in alpha diversity (observed features) across treatment groups using the Kruskal-Wallis test. Following this, it sets up a dedicated directory (`$diffabun`) for differential abundance results. The script then filters the ASV feature table to focus on comparing "duckweed" and "water" sample types. To facilitate species-level analysis, it collapses the ASVs to taxonomic level 7. The core of the differential abundance testing is performed using the ANCOM-BC method, comparing species-level abundances between the "duckweed" and "water" groups, with "duckweed" set as the reference. Finally, the significant differences identified by ANCOM-BC are visualized using a differential abundance barplot, highlighting taxa that are significantly more or less abundant between the compared sample types based on a significance threshold of 0.001.

  ```bash
# === Step 3D: Differential Abundance Testing  ===

# Visualize Observed Features vs. Treatment Group
echo "visualizing observed features vs. treatment group..."
qiime diversity alpha-group-significance \
  --i-data $core_metrics_dir/alpha_diversity.qza \
  --m-metadata-file $rddir/metadata.tsv \
  --p-metric observed_features \
  --p-group-column treatment_group \
  --p-m-method kruskal-wallis \
  --o-visualization $divres/observed_features_vs_treatment.qzv

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
```
</details>

<details>
 <summary><b> Final Step: Log Completion </b></summary>

This final section serves to log the completion of the entire analysis pipeline. The date command is executed, which prints the current date and time to the console, providing a timestamp for when the script finished running. Following this, the echo "pipeline completed" command prints a clear message to the standard output, indicating to the user that all the steps in the script have been executed. This is a simple but important step for confirming the successful completion of the analysis.

```bash
# === Final Step: Log Completion ===
date

echo "pipeline completed"
```
