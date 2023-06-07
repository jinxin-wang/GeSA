--> A rule to generate a bed from mutect2 vcf, on tumor versus normal with panel of normals

- input files : 
VCF file containing the variants identified in the tumor sample compared to the normal sample
```
        Mutect2_vcf = "Mutect2_TvNp/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_twicefiltered_TvNp.vcf.gz"
```
- output files :
Variant BED file: This is the output BED file that contains the genomic regions of the filtered variants from the Tumor-Normal VCF file. The BED file should include the chromosome, start position, end position, and any additional relevant information for each variant.
```
        BED = temp("variant_bed_TvN/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvN.bed")
```
-->  Run samtools mpileup, on tumor versus normal with panel of normals

- input files :
```
        BED = "variant_bed_TvNp/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp.bed",
        BAM = "bam/{tsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam",
        BAI = "bam/{tsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam.bai"
```
- output files :
```
        PILEUP = temp("pileup_TvN/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvN.pileup.gz")
```

-->  A rule to split mutect2 results in pieces

- input files : 
```
        Mutect2_vcf = "Mutect2_TvNp/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_twicefiltered_TvNp.vcf.gz",
        vcf_index = "Mutect2_TvNp/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_twicefiltered_TvNp.vcf.gz.tbi"
```
- output files :
```
        interval_vcf_bcftools = temp("Mutect2_TvNp_oncotator_tmp/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp_ON_{interval}_bcftools.vcf.gz"),
        interval_vcf          = temp("Mutect2_TvNp_oncotator_tmp/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp_ON_{interval}.vcf.gz")
```

--> A rule to annotate mutect2 tumor versus normal and panel of normal results with oncotator  

- input files : 
```
        interval_vcf = "Mutect2_TvNp_oncotator_tmp/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp_ON_{interval}.vcf.gz"
```
- output files :
```
        MAF = temp("oncotator_TvNp_tmp/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_ON_{interval}_annotated_TvNp.TCGAMAF")
```

--> concatenate oncotator TvN_pon

- input files : 
```
        maf = expand("oncotator_TvNp_tmp/{{tsample}}_Vs_{{nsample}}_PON_{{panel_of_normal}}_ON_{mutect_interval}_annotated_TvNp.TCGAMAF", mutect_interval=mutect_intervals)
```
- output files :
```
        concatened_oncotator = temp("oncotator_TvNp/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_annotated_TvNp.TCGAMAF"),
        tmp_list = temp("oncotator_TvNp_tmp/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp_oncotator_tmp.list")
```

--> A rule to simplify oncotator output on tumor vs normal samples with panel of normal

- input files : 
```
        maf="oncotator_TvNp/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_annotated_TvNp.TCGAMAF"
```
- output files :
```
        maf = "oncotator_TvNp_maf/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp_selection.TCGAMAF",
        tsv = temp("oncotator_TvNp_tsv/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp.tsv")
```

--> A rule to simplify oncotator output on tumor vs normal samples with panel of normal

- input files : 
```
        tsv = "oncotator_TvNp_tsv/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp.tsv",
        pileup = "pileup_TvN/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvN.pileup.gz"
```
- output files :
```
        tsv = temp("oncotator_TvNp_tsv_pileup/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp_with_pileup.tsv")
```

--> A rule to simplify oncotator output on tumor vs normal samples with panel of normal

- input files : 
```
     tsv = "oncotator_TvNp_tsv_pileup/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp_with_pileup.tsv"
```
- output files :
```
        tsv = "oncotator_TvNp_tsv_COSMIC/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp_with_COSMIC.tsv"
```

