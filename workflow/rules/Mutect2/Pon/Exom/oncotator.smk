# A rule to generate a bed from mutect2 vcf, on tumor versus normal with panel of normals
rule extract_exom_mutect2_pon:
    input:
        Mutect2_vcf = "Mutect2_TvNp/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_twicefiltered_TvNp.vcf.gz",
        Mutect2_vcf_index = "Mutect2_TvNp/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_twicefiltered_TvNp.vcf.gz.tbi",
    output:
        exom_Mutect2 = temp("Mutect2_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_twicefiltered_TvNp_exom_unsorted.vcf.gz")
    log:
        "logs/Mutect2_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvN.vcf.log"
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
rule sort_exom_mutect2_pon:
    input:
        Mutect2_vcf = "Mutect2_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_twicefiltered_TvNp_exom_unsorted.vcf.gz"
    output:
        exom_Mutect2 = temp("Mutect2_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_twicefiltered_TvNp_exom.vcf.gz"),
    log:
        "logs/Mutect2_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvN_sort.log"
    params:
        queue = "shortq",
        vcfsort = config["vcfsort"]["app"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        'bgzip -d {input.Mutect2_vcf} && '
        '{params.vcfsort} Mutect2_TvNp_exom/{wildcards.tsample}_Vs_{wildcards.nsample}_PON_{wildcards.panel_of_normal}_twicefiltered_TvNp_exom_unsorted.vcf > Mutect2_TvNp_exom/{wildcards.tsample}_Vs_{wildcards.nsample}_PON_{wildcards.panel_of_normal}_twicefiltered_TvNp_exom.vcf && '
        'bgzip Mutect2_TvNp_exom/{wildcards.tsample}_Vs_{wildcards.nsample}_PON_{wildcards.panel_of_normal}_twicefiltered_TvNp_exom.vcf'

# A rule to generate a bed from mutect2 vcf, on tumor versus normal with panel of normals
rule index_exom_mutect2_pon:
    input:
        exom_Mutect2 = "Mutect2_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_twicefiltered_TvNp_exom.vcf.gz"
    output:
        exom_Mutect2 = temp("Mutect2_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_twicefiltered_TvNp_exom.vcf.gz.tbi")
    log:
        "logs/Mutect2_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvN_index.log"
    params:
        queue = "shortq",
        gatk = config["gatk"]["app"]
    threads : 1
    conda: "pipeline_GATK_2.1.4_V2"
    resources:
        mem_mb = 10240
    shell:
        '{params.gatk} IndexFeatureFile -F {input.exom_Mutect2} 2> {log}'

# A rule to generate a bed from mutect2 vcf, on tumor versus normal with panel of normals
rule get_variant_bed_pon_exom:
    input:
        Mutect2_vcf = "Mutect2_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_twicefiltered_TvNp_exom.vcf.gz",
        Mutect2_vcf_index = "Mutect2_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_twicefiltered_TvNp_exom.vcf.gz.tbi"
    output:
        BED = temp("variant_bed_TvN_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvN_exom.bed")
    log:
        "logs/variant_bed_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvN_exom.bed.log"
    params:
        queue = "shortq",
        vcf2bed = config["vcf2bed"]["app"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        'zcat {input.Mutect2_vcf} | python2 {params.vcf2bed} - > {output.BED} 2> {log}'

# Run samtools mpileup, on tumor versus normal with panel of normals
rule samtools_mpileup_pon_exom:
    input:
        BED = "variant_bed_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp_exom.bed",
        BAM = "bam/{tsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam",
        BAI = "bam/{tsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam.bai"
    output:
        PILEUP = temp("pileup_TvN_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvN_exom.pileup.gz")
    log:
        "logs/pileup_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvN_exom.pileup.log"
    params:
        queue = "shortq",
        samtools = config["samtools"]["app"],
        genome_fasta = config["gatk"][config["samples"]]["genome_fasta"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        '{params.samtools} mpileup -a -B -l {input.BED} -f {params.genome_fasta} {input.BAM} | gzip - > {output.PILEUP} 2> {log}'

# A rule to annotate mutect2 tumor versus normal and panel of normal results with oncotator  
rule oncotator_pon_exom:
    input:
        Mutect2_vcf = "Mutect2_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_twicefiltered_TvNp_exom.vcf.gz",
        Mutect2_vcf_index = "Mutect2_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_twicefiltered_TvNp_exom.vcf.gz.tbi",
    output:
        MAF = temp("oncotator_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_annotated_TvNp_exom.TCGAMAF")
    params:
        queue = "shortq",
        DB    = config["oncotator"][config["samples"]]["DB"],
        ref   = config["oncotator"][config["samples"]]["ref"],
        oncotator = config["oncotator"]["app"],
    log:
        "logs/oncotator_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_annotated_TvNp_exom.TCGAMAF.log"
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        '{params.oncotator} --input_format=VCF --output_format=TCGAMAF --tx-mode EFFECT --db-dir={params.DB} {input.Mutect2_vcf} {output.MAF} {params.ref} 2> {log}'

## A rule to simplify oncotator output on tumor vs normal samples with panel of normal
rule oncotator_reformat_TvN_pon_exom:
    input:
        maf="oncotator_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_annotated_TvNp_exom.TCGAMAF"
    output:
        maf = "oncotator_TvNp_maf_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp_selection_exom.TCGAMAF",
        tsv = temp("oncotator_TvNp_tsv_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp_exom.tsv")
    log:
        "logs/oncotator_TvNp_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_annotated_TvNp_selection_exom.log"
    params:    
        queue = "shortq",
        oncotator_extract_TvN = config["oncotator"]["scripts"]["extract_tumor_vs_normal"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        'python2.7 {params.oncotator_extract_TvN} {input.maf} {output.maf} {output.tsv} 2> {log}'

## A rule to simplify oncotator output on tumor vs normal samples with panel of normal
rule oncotator_with_pileup_TvN_pon_exom:
    input:
        tsv = "oncotator_TvNp_tsv_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp_exom.tsv",
        pileup = "pileup_TvN_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvN_exom.pileup.gz"
    output:
        tsv = temp("oncotator_TvNp_tsv_pileup_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp_with_pileup_exom.tsv")
    log:
        "logs/oncotator_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_annotated_TvNp_with_pileup_exom.log"
    params:
        queue = "shortq",
        oncotator_cross_pileup = config["oncotator"]["scripts"]["pileup"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        'python {params.oncotator_cross_pileup} {input.pileup} {input.tsv} {output.tsv}'

## A rule to simplify oncotator output on tumor vs normal samples with panel of normal
rule oncotator_with_COSMIC_TvN_pon_exom:
    input:
        tsv = "oncotator_TvNp_tsv_pileup_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp_with_pileup_exom.tsv"
    output:
        tsv = "oncotator_TvNp_tsv_COSMIC_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_TvNp_with_COSMIC_exom.tsv"
    log:
        "logs/oncotator_exom/{tsample}_Vs_{nsample}_PON_{panel_of_normal}_annotated_TvNp_with_COSMIC_exom.log"
    params:
        queue = "shortq",
        oncotator_cross_cosmic = config["oncotator"]["scripts"]["cosmic_t_n"],
        cosmic_mutation = config["oncotator"][config["samples"]]["cosmic_mutation"],
        cancer_census_oncogene = config["oncotator"][config["samples"]]["cancer_census_oncogene"],
        cancer_census_tumorsupressor = config["oncotator"][config["samples"]]["cancer_census_tumorsupressor"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        'python2.7 {params.oncotator_cross_cosmic}  {input.tsv} {output.tsv} {params.cosmic_mutation} {params.cancer_census_oncogene} {params.cancer_census_tumorsupressor} 2> {log}'

