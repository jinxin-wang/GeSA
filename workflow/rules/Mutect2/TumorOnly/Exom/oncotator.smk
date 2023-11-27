# A rule to generate a bed from mutect2 vcf, on tumor only 
rule extract_exom_mutect2_tumor_only:
    input:
        Mutect2_vcf = "Mutect2_T/{tsample}_tumor_only_twicefiltered_T.vcf.gz",
        Mutect2_vcf_index = "Mutect2_T/{tsample}_tumor_only_twicefiltered_T.vcf.gz.tbi",
    output:
        exom_Mutect2 = temp("Mutect2_T_exom/{tsample}_tumor_only_twicefiltered_T_exom_unsorted.vcf.gz")
    log:
        "logs/Mutect2_T_exom/{tsample}_tumor_only_T.vcf.log"
    params:
        queue = "shortq",
        bcftools = config["bcftools"]["app"],
        exom_bed = config["bcftools"][config["samples"]]["exom_bed"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        '{params.bcftools} view -l 9 -R {params.exom_bed} -o {output.exom_Mutect2} {input.Mutect2_vcf} 2> {log}'
 
# A rule to sort exom vcf
rule sort_exom_mutect2_tumor_only:
    input:
        Mutect2_vcf = "Mutect2_T_exom/{tsample}_tumor_only_twicefiltered_T_exom_unsorted.vcf.gz"
    output:
        exom_gz  = "Mutect2_T_exom/{tsample}_tumor_only_twicefiltered_T_exom.vcf.gz",
    log:
        "logs/Mutect2_T_exom/{tsample}_tumor_only_T_sort.log"
    params:
        queue   = "shortq",
        vcfsort = config["vcfsort"]["app"],
        bgzip   = config["bgzip"]["app"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        '{params.bgzip} -d {input.Mutect2_vcf} 2> {log} && '
        '{params.vcfsort} Mutect2_T_exom/{wildcards.tsample}_tumor_only_twicefiltered_T_exom_unsorted.vcf > Mutect2_T_exom/{wildcards.tsample}_tumor_only_twicefiltered_T_exom.vcf  2>> {log} && '
        '{params.bgzip} Mutect2_T_exom/{wildcards.tsample}_tumor_only_twicefiltered_T_exom.vcf 2>> {log} '
        
# A rule to generate a bed from mutect2 vcf, on tumor only 
rule index_exom_mutect2_tumor_only:
    input:
        exom_Mutect2 = "Mutect2_T_exom/{tsample}_tumor_only_twicefiltered_T_exom.vcf.gz"
    output:
        exom_Mutect2 = "Mutect2_T_exom/{tsample}_tumor_only_twicefiltered_T_exom.vcf.gz.tbi"
    log:
        "logs/Mutect2_T_exom/{tsample}_tumor_only_T_index.log"
    params:
        queue = "shortq",
        # gatk = config["gatk"]["app"],
        gatk = config["gatk"][config["samples"]]["app"],
    threads : 1
    conda: "pipeline_GATK_2.1.4_V2"
    resources:
        mem_mb = 10240
    shell:
        # '{params.gatk} IndexFeatureFile -F {input.exom_Mutect2} 2> {log}' 
        '{params.gatk} IndexFeatureFile -I {input.exom_Mutect2} 2> {log}'
        
# A rule to generate a bed from mutect2 vcf, on tumor only 
rule get_variant_bed_tumor_only_exom:
    input:
        Mutect2_vcf = "Mutect2_T_exom/{tsample}_tumor_only_twicefiltered_T_exom.vcf.gz",
        Mutect2_vcf_index = "Mutect2_T_exom/{tsample}_tumor_only_twicefiltered_T_exom.vcf.gz.tbi"
    output:
        BED = "variant_bed_T_exom/{tsample}_tumor_only_T_exom.bed"
    log:
        "logs/variant_bed_T_exom/{tsample}_tumor_only_T_exom.bed.log"
    params:
        queue = "shortq",
        vcf2bed = config["vcf2bed"]["app"]
    threads : 1
    resources:
        mem_mb = 51200
    shell:
        'zcat {input.Mutect2_vcf} | python2 {params.vcf2bed} - > {output.BED} 2> {log}'

# Run samtools mpileup, on tumor only 
rule samtools_mpileup_tumor_only_exom:
    input:
        BED = "variant_bed_T_exom/{tsample}_tumor_only_T_exom.bed",
        BAM = "bam/{tsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam",
        BAI = "bam/{tsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam.bai"
    output:
        PILEUP = "pileup_T_exom/{tsample}_tumor_only_T_exom.pileup.gz"
    log:
        "logs/pileup_T_exom/{tsample}_tumor_only_T_exom.pileup.log"
    params:
        queue = "shortq",
        samtools = config["samtools"]["app"],
        genome_fasta = config["gatk"][config["samples"]]["genome_fasta"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        '{params.samtools} mpileup -a -B -l {input.BED} -f {params.genome_fasta} {input.BAM} | gzip - > {output.PILEUP} 2> {log}'

# A rule to annotate mutect2 tumor only results with oncotator 
rule oncotator_tumor_only_exom:
    input:
        Mutect2_vcf = "Mutect2_T_exom/{tsample}_tumor_only_twicefiltered_T_exom.vcf.gz",
        Mutect2_vcf_index = "Mutect2_T_exom/{tsample}_tumor_only_twicefiltered_T_exom.vcf.gz.tbi"
    output:
        MAF="oncotator_T_exom/{tsample}_tumor_only_annotated_T_exom.TCGAMAF"
    params:
        queue = "shortq",
        DB    = config["oncotator"][config["samples"]]["DB"],
        ref   = config["oncotator"][config["samples"]]["ref"],
        oncotator = config["oncotator"]["app"],
    log:
        "logs/oncotator_T_exom/{tsample}_tumor_only_annotated_T_exom.TCGAMAF"
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        '{params.oncotator} --input_format=VCF --output_format=TCGAMAF --tx-mode EFFECT --db-dir={params.DB} {input.Mutect2_vcf} {output.MAF} {params.ref} 2> {log}'

## A rule to simplify oncotator output on tumor only samples
rule oncotator_reformat_tumor_only_exom:
    input:
        maf="oncotator_T_exom/{tsample}_tumor_only_annotated_T_exom.TCGAMAF"
    output:
        maf ="oncotator_T_maf_exom/{tsample}_tumor_only_T_selection_exom.TCGAMAF",
        tsv ="oncotator_T_tsv_exom/{tsample}_tumor_only_T_exom.tsv"
    log:
        "logs/oncotator_exom/{tsample}_tumor_only_T_selection_exom.log"
    params:
        queue = "shortq",
        oncotator_extract_Tonly = config["oncotator"]["scripts"]["extract_tumor_only"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        'python2.7 {params.oncotator_extract_Tonly} {input.maf} {output.maf} {output.tsv} 2> {log}'

## A rule to simplify oncotator output on tumor only samples
rule oncotator_with_pileup_tumor_only_exom:
    input:
        tsv = "oncotator_T_tsv_exom/{tsample}_tumor_only_T_exom.tsv",
        pileup = "pileup_T_exom/{tsample}_tumor_only_T_exom.pileup.gz"
    output:
        tsv = "oncotator_T_tsv_pileup_exom/{tsample}_tumor_only_T_with_pileup_exom.tsv"
    log:
        "logs/oncotator_exom/{tsample}_tumor_only_T_selection_with_pileup_exom.log"
    params:
        queue = "shortq",
        oncotator_cross_pileup = config["oncotator"]["scripts"]["pileup"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        'python {params.oncotator_cross_pileup} {input.pileup} {input.tsv} {output.tsv}'

## A rule to simplify oncotator output on tumor only samples
rule oncotator_with_COSMIC_tumor_only_exom:
    input:
        tsv = "oncotator_T_tsv_pileup_exom/{tsample}_tumor_only_T_with_pileup_exom.tsv"
    output:
        tsv = "oncotator_T_tsv_COSMIC_exom/{tsample}_tumor_only_T_with_COSMIC_exom.tsv"
    log:
        "logs/oncotator_exom/{tsample}_tumor_only_T_selection_with_COSMIC_exom.log"
    params:
        queue = "shortq",
        oncotator_cross_cosmic = config["oncotator"]["scripts"]["cosmic_t_only"],
        cosmic_mutation = config["oncotator"][config["samples"]]["cosmic_mutation"],
        cancer_census_oncogene = config["oncotator"][config["samples"]]["cancer_census_oncogene"],
        cancer_census_tumorsupressor = config["oncotator"][config["samples"]]["cancer_census_tumorsupressor"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        'python2.7 {params.oncotator_cross_cosmic}  {input.tsv} {output.tsv} {params.cosmic_mutation} {params.cancer_census_oncogene} {params.cancer_census_tumorsupressor} 2> {log}'

use rule compr_with_gzip_abstract as oncotator_reformat_exom_gzip_Tonly with:
    input:
        "oncotator_T_maf_exom/{tsample}_tumor_only_T_selection_exom.TCGAMAF",
    output:
        "oncotator_T_maf_exom/{tsample}_tumor_only_T_selection_exom.TCGAMAF.gz",

use rule compr_with_gzip_abstract as COSMIC_exom_gzip_Tonly with:
    input:
        "oncotator_T_tsv_COSMIC_exom/{tsample}_tumor_only_T_with_COSMIC_exom.tsv"
    output:
        "oncotator_T_tsv_COSMIC_exom/{tsample}_tumor_only_T_with_COSMIC_exom.tsv.gz"
