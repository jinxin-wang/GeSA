### 1. Description of Mutect2 Tumor Only vs Panel of Normals Submodule



### 2. Description of Interfaces and Dependencies
rule Mutect2_tumor_only_pon:

The rule "Mutect2_tumor_only_pon" likely involves running the MuTect2 variant calling tool on tumor samples using a Panel of Normals (PoN). The purpose of this rule is to identify somatic mutations specific to the tumor samples while leveraging the information from the PoN to filter out potential germline variants or technical artifacts.

- Specifications of Input Files
-> tumor bam :This input file represents the aligned sequence data (in BAM format) for the tumor sample being analyzed. The actual file path depends on the value of config["remove_duplicates"]. If remove_duplicates is set to True, the file path will be "bam/{tsample}.nodup.recal.bam", indicating that the duplicate reads have been removed from the BAM file. If remove_duplicates is False, the file path will be "bam/{tsample}.recal.bam", indicating that the BAM file includes duplicate reads.
-> tumor bai :This input file represents the index file (BAI) associated with the tumor BAM file. The BAI file is used for efficient access and querying of the BAM file. Similar to tumor_bam, the actual file path depends on the value of config["remove_duplicates"]. If remove_duplicates is True, the file path will be "bam/{tsample}.nodup.recal.bam.bai". If remove_duplicates is False, the file path will be "bam/{tsample}.recal.bam.bai".
-> panel of normal :
```
        tumor_bam = "bam/{tsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam",
        tumor_bai = "bam/{tsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam.bai",
        panel_of_normal = "PoN/{panel_of_normal}.vcf",
```
- Ouput Files

```
        VCF   = temp("Mutect2_Tp_tmp/{tsample}_PON_{panel_of_normal}_Tp_ON_{interval}.vcf.gz"),
        INDEX = temp("Mutect2_Tp_tmp/{tsample}_PON_{panel_of_normal}_Tp_ON_{interval}.vcf.gz.tbi"),
        STATS = temp("Mutect2_Tp_tmp/{tsample}_PON_{panel_of_normal}_Tp_ON_{interval}.vcf.gz.stats"),
```
- Genome Reference

- Packages and Versions

### 3. Issues and TODO
