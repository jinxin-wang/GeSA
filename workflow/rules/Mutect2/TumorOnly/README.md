### 1. Description of Mutect2 Tumor Only Submodule
The Mutect2 Tumor Only submodule is a component of the MuTect2 tool, which is used for somatic variant calling in tumor samples using next-generation sequencing data. The Tumor Only submodule specifically focuses on analyzing tumor-only sequencing data, where there is no corresponding normal sample available for comparison.

The purpose of the Mutect2 Tumor Only submodule is to identify somatic mutations, which are genetic alterations that are present only in the tumor cells and not in the normal cells. By analyzing the tumor sequencing data alone, the submodule aims to detect these somatic mutations and distinguish them from germline variants or sequencing artifacts.

### 2. Description of Interfaces and Dependencies
rule Mutect2_tumor_only:

This rule provides a standardized and reproducible way to perform somatic variant calling specifically on tumor samples without the availability of corresponding normal samples.
The rule aims to identify somatic mutations, which are genetic alterations that are present only in the tumor cells and not in the normal cells. By using the MuTect2 tool, the rule leverages its algorithm and strategies to detect somatic mutations from tumor-only sequencing data.The rule also likely includes steps to assess the quality of the sequencing data and apply appropriate filters to remove potential false positives or artifacts. This helps to increase the confidence in the identified somatic mutations and reduce the number of false-positive calls.

- Specifications of Input Files

these inputs is specify the location and names of the tumor BAM and BAI files required for the Mutect2 variant calling analysis. These files contain the aligned sequencing data for the tumor sample, which serves as the primary input for the variant calling process.

```
        tumor_bam = "bam/{tsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam",
        tumor_bai = "bam/{tsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam.bai",
```
- Ouput Files
```
        VCF   = temp("Mutect2_T_tmp/{tsample}_tumor_only_T_ON_{interval}.vcf.gz"),
        INDEX = temp("Mutect2_T_tmp/{tsample}_tumor_only_T_ON_{interval}.vcf.gz.tbi"),
        STATS = temp("Mutect2_T_tmp/{tsample}_tumor_only_T_ON_{interval}.vcf.gz.stats")
```
- Genome Reference

- Packages and Versions

### 3. Issues and TODO
