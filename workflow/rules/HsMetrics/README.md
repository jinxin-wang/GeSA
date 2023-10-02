### 1. Description of HS Module

 HS module for mapping stats refers to a specialized component or tool that is designed to analyze and visualize statistical data related to the human genome or genomic variations. This module provides features and functionalities to map and represent genomic data, allowing researchers, geneticists, and other stakeholders to gain insights into various genomic patterns and associations.
 Among its features and capabilties we can site : 
 Genome Mapping as the module allows users to map genomic data onto the human genome reference sequence, typically represented by chromosomes. It enables the visualization of genomic variations, such as single nucleotide polymorphisms (SNPs), copy number variations (CNVs), or structural variations, in their genomic context.
 The module offers an interactive genome browser that allows users to navigate, zoom in/out, and explore genomic regions of interest
 Users can compare genomic data between different samples or populations within the mapping stats module. This feature allows for identifying genomic variations that are specific to certain populations...
 the overall objective is to provide a visual representation of statistical genomic data, enabling users to analyze and interpret genomic patterns, variations, and associations.
 
### 2. Description of Interfaces and Dependencies

- Specifications of Input Files: 

Genome Alignment File (BAM/SAM): BAM (Binary Alignment/Map) or SAM (Sequence Alignment/Map) files contain aligned sequencing reads mapped to a reference genome. These files store the genomic coordinates, sequencing quality scores, and other alignment information for each read. Alignment files are typically generated through alignment tools like BWA or Bowtie.

BAI (Binary Alignment Index) file is a commonly used index file format in genomics for quick retrieval of aligned reads from a BAM (Binary Alignment/Map) file. The BAI file is created alongside the BAM file and allows for efficient querying of specific genomic regions. 

```
        bam = "bam/{sample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{sample}.recal.bam",
        bai = "bam/{sample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{sample}.recal.bam.bai",
```
- Ouput Files
```
        "mapping_QC/HsMetrics/{sample}_HsMetrics.tsv"
```
- Genome Reference

The file is related to the b37 reference genome (GRCh37/hg19) and contains intervals or regions defined by 100-kilobase windows for specific chromosomes (possibly the major chromosomes in the 1000 Genomes Project reference panel).
The purpose of this interval file is likely to define regions of interest or specific genomic intervals for calculating high-throughput sequencing metrics. These metrics may include coverage, GC content, duplication rates, or other quality control measures to assess the performance and characteristics of sequencing data in targeted regions of the genome
```
"hsmetrics_interval": "/mnt/beegfs/userdata/i_padioleau/genome_data/b37_GATK/human_g1k_v37_major_chr_100kb_windows.interval"
```
The bait interval file is typically used in genomic capture or target enrichment experiments, where specific regions of interest are captured or enriched before sequencing. These regions are often referred to as "baits" and are designed to capture specific genomic regions of interest, such as exons, gene panels, or other targeted regions.
```
"hsmetrics_bait": "/mnt/beegfs/userdata/i_padioleau/genome_data/b37_GATK/human_g1k_v37_major_chr_100kb_windows.interval"
```
- Packages and Versions

### 3. Issues and TODO
