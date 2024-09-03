## Introduction
GESA (**Ge**nome **S**equencing **A**nalysis Pipeline) is a workflow designed to detect variants in whole genome, whole exome, or targeted sequencing data, specifically for Human and Mouse samples. GESA can handle various scenarios including tumor-only, tumor/(matched/unmatched) normal, tumor/Panel of Normal (PoN), or tumor/(matched/unmatched) normal/PoN, as well as cell line data.

GESA was first prototyped by Ismael and Leonardo Panunzi. [Jinxin WANG](https://github.com/jinxin-wang/) refactored the prototype scripts and continued development alongside his colleagues Andrei IURCHENKO and ???. Significant contributions have also been made by [Jomar SANGALANG](https://github.com/jsangalang), [Andrei Ivashkin](https://github.com/andrrrsss), [
Thibault DAYRIS](), Yoann PRADAT, and others.

## Summary

The pipeline consists of four modules that operate in a serial fashion. Each performs a specific task, reading from standard input files and producing standard output files (e.g., fastq, bam, vcf, maf). The pipeline's starting point and ending point can be dynamically set, providing great flexibility in analysis workflows. This modular design enables you to easily expand the pipeline with your own tools and analyses. 

#### 1. Preprocessing 
  - samtools
  - fastp, fastq, bwa-mem2, gatk bqsr
  - msodepth, HsMetrics, Flagstat
    
#### 2. Variant Calling  
  - gatk mutect2
  - haplotypeCaller
  - facets, cnv_facets, facets suites
  - manta, SvABA
    
#### 3. Annotation
  - annovar
  - oncotator
  - vep
  - gatk funcotator
  - oncokb
    
#### 4. Analysis
  - snp-pileup, mantis
  - SigProfiler
    
### TODO:
  - test SigProfiler, mantis, facets_suites, manta, SvABA,
  - remove annotation submodules extracted from metaprism
  - clean up data module, leaving only concat block 
  - config.json -> config.yaml, then add comments
  - concatenate variants (somatic and germline)
  - Jomar -> PoN, etc.
  - build references (GRCh37/hg19/GRCh38/hg38)
  - logging 
  - Documents
  - refactor and release in nextflow
  
## Usage

1. 以Preprocessing模块为入口
2. 以Variant Calling模块为入口
3. 以Annotation模块为入口
4. 以Analysis模块为入口

## Contributions & Support

## Citations
