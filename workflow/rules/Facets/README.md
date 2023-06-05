### 1. Description of Facets Module

FACETS (Fraction and Allele-specific Copy Number Estimates from Tumor Sequencing) is used for analyzing copy number alterations (CNAs) and identifying allele-specific copy number changes in tumor samples using next-generation sequencing (NGS) data.

FACETS is a powerful tool for studying copy number alterations and inferring allele-specific copy number changes in tumor samples. It has been widely used in cancer genomics research to gain insights into tumor heterogeneity, identify driver alterations, and understand the underlying genomic mechanisms involved in cancer development and progression.

### 2. Description of Interfaces and Dependencies

--> rule cnv_facets:

- Specifications of Input Files
The input files for the rule "cnv_facets" in a genomic analysis pipeline using FACETS may vary depending on the specific implementation and configuration.

Tumor BAM file: This is the aligned sequencing data file (in BAM format) for the tumor sample. It contains the mapped reads from the sequencing experiment for the tumor sample.

Normal BAM file: This is the aligned sequencing data file (in BAM format) for the corresponding normal or reference sample. The normal sample is used as a control to compare against the tumor sample and identify copy number alterations.
```
        tumor_bam = "bam/{tsample}.nodup.recal.bam",
        tumor_bai = "bam/{tsample}.nodup.recal.bam.bai",
        normal_bam = "bam/{nsample}.nodup.recal.bam",
        normal_bai = "bam/{nsample}.nodup.recal.bam.bai"
```
- Ouput Files
the "cnv_facets" rule generates a compressed VCF (Variant Call Format) file with the naming convention based on the tumor sample and normal sample being compared.
```
        csv = "cnv_facets/{tsample}_Vs_{nsample}.vcf.gz",
        csv_index = "cnv_facets/{tsample}_Vs_{nsample}.vcf.gz.tbi"
 ```       
- Genome Reference
When running the "cnv_facets" rule or the FACETS tool in general, you would need to provide the path or location of the genome reference file as a separate input parameter. This allows the tool to align the sequencing reads, compare them to the reference sequence, and identify copy number alterations and variants.
Genome reference used here is GRCh37 (hg19) for human , and mm9 for mouse .
 ``` 
    "cnv_facets":{
        "app": "~/.conda/envs/pipeline_GATK_2.1.4_V2/bin/cnv_facets.R",
        "human": {
            "cval": "25 400",
            "ref": "hg19",
        }, 
        "mouse": {
            "cval": "25 400",
            "ref": "mm9",
        }, 
    },
``` 
--> rule facets_snp_pilleup:
This rule is specifically focused on generating SNP pileup files for subsequent analysis using FACETS.
The purpose of generating SNP pileup files is to provide input for FACETS to perform allele-specific copy number estimation. By analyzing the SNP pileup data, FACETS can infer the allele-specific copy number profiles and detect copy number alterations in tumor samples.

- Specifications of Input Files
Tumor BAM file: This is the aligned sequencing data file (in BAM format) for the tumor sample. It contains the mapped reads from the sequencing experiment for the tumor sample.

Normal BAM file: This is the aligned sequencing data file (in BAM format) for the corresponding normal or reference sample. The normal sample is used as a control to compare against the tumor sample and identify copy number alterations.
```
        TUMOR_BAM = "bam/{tsample}.nodup.recal.bam",
        NORMAL_BAM = "bam/{nsample}.nodup.recal.bam"
```

- Specifications of output Files
the "facets_snp_pileup" rule generates a compressed CSV (Comma-Separated Values) file containing the FACETS results for the comparison between the tumor sample and the normal sample
```
       CSV = "facets/{tsample}_Vs_{nsample}_facets.csv.gz"
```
- Packages and Versions

### 3. Issues and TODO

[cnv_facets github](https://github.com/dariober/cnv_facets)

#### [major, minor allele and copy number](https://cancer.sanger.ac.uk/cosmic/help/cnv/overview)

1. Minor Allele: the number of copies of the least frequent allele eg if ABB, minor allele = A ( 1 copy) and major allele = B ( 2 copies)
2. Copy Number: the sum of the major and minor allele counts eg if ABB, copy number = 3

#### [heterozygous mutation](https://www.genome.gov/genetics-glossary/heterozygous)

The presence of two different alleles at a particular gene locus. A heterozygous genotype may include one normal allele and one mutated allele or two different mutated alleles (compound heterozygote)

#### [Chapter 7 FACETS: allele-specific copy number and clonal heterogeneity analysis tool for high-throughput DNA sequencing](https://link.springer.com/content/pdf/10.1007/978-1-0716-2293-3.pdf?pdf=button%20sticky)
