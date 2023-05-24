### 1. Description of Annovar Module

  The Annovar module is a bioinformatics tool commonly used in genomic research and analysis.
The main purpose of Annovar, which stands for "Annotate Variation," is to annotate genetic variants found in high-throughput sequencing data.
The module takes input in the form of variant call format (VCF) files, which are commonly used to store genetic variation information. Annovar processes the variants and provides comprehensive annotations to aid in the interpretation of the genetic data. Annovar's annotations include details on the functional implications of the variants, their genomic positions, and any potential associations they may have with well-known genes or genetic traits.

### 2. Description of Interfaces and Dependencies

- Specifications of Input Files
- 
In the Annovar module, there are specific input files that are required to perform variant annotation. The main input files used by Annovar are :

1. Variant Call Format (VCF) file:  is the primary input file for Annovar , can be generated from various sequencing technologies, such as whole-genome sequencing (WGS), whole-exome sequencing (WES) , and  contains genetic variant information, including chromosome, position, reference allele, alternate allele, genotype, quality scores, and additional annotations.
```
    input:
        vcf = "haplotype_caller_filtered/{sample}_germline_variants_filtered.vcf.gz"
```
2. Reference genome file:  typically in FASTA format and is required to accurately map the variants to their genomic coordinates
ANNOVAR can be used with different reference genome assemblies, including hg19 (GRCh37) , it can be obtained from the ANNOVAR website
```
 "ref": "hg19"
```
4. Annotation database files: 
5. Filter file (optional)


- Ouput Files

- Genome Reference

- Packages and Versions

### 3. Issues and TODO
