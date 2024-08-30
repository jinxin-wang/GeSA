## Introduction
GESA (**Ge**nome **S**equencing **A**nalysis Pipeline) is a workflow designed to detect variants in whole genome, whole exome, or targeted sequencing data, specifically for Human and Mouse samples. GESA can handle various scenarios including tumor-only, tumor/(matched/unmatched) normal, tumor/Panel of Normal (PoN), or tumor/(matched/unmatched) normal/PoN, as well as cell line data.

GESA was first prototyped by Ismael and Leonardo. Jinxin refactored the prototype scripts and continued development alongside his colleagues Andrei and ???. Significant contributions have also been made by Jomar, [Andrei Ivashkin](https://github.com/andrrrsss), Yoann, and others.

## Summary
#### 1. Preprocessing 
  - samtools
  - fastp, fastq, bwa-mem2, gatk bqsr
  - msodepth, HsMetrics, Flagstat
    
#### 2. Variant Calling  
  - gatk mutect2
  - haplotypeCaller, annovar
  - facets, cnv_facets, facets suites
  - manta, SvABA
    
#### 3. Annotation
  - oncotator
  - vep
  - gatk funcotator
  - oncokb
    
#### 4. Analysis
  - snp-pileup, mantis
  - SigProfiler
    
### TODO:
  - test SigProfiler, mantis, facets_suites, manta, SvABA, 
  - concatenate variants (somatic and germline)
  - Jomar -> PoN, etc.
  - build references
  - Documents
  - refactor and release in nextflow
  
## Usage

## Contributions & Support

## Citations
