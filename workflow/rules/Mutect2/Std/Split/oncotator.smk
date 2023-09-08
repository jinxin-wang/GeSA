# A rule to generate a bed from mutect2 vcf  
rule get_variant_bed:
    input:
        Mutect2_vcf = "Mutect2_TvN/{tsample}_Vs_{nsample}_twicefiltered_TvN.vcf.gz"
    output:
        BED = temp("variant_bed_TvN/{tsample}_Vs_{nsample}_TvN.bed"),
    log:
        "logs/variant_bed_TvN/{tsample}_Vs_{nsample}_TvN.bed.log"
    params:
        queue   = "shortq",
        vcf2bed = config["vcf2bed"]["app"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        'zcat {input.Mutect2_vcf} | python2 {params.vcf2bed} - > {output.BED} 2> {log}'

## Run samtools mpileup 
rule samtools_mpileup:
    input:
        BED = "variant_bed_TvN/{tsample}_Vs_{nsample}_TvN.bed",
        BAM = "bam/{tsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam",
        BAI = "bam/{tsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam.bai"
    output:
        PILEUP = temp("pileup_TvN/{tsample}_Vs_{nsample}_TvN.pileup.gz"),
    log:
        "logs/pileup_TvN/{tsample}_Vs_{nsample}_TvN.pileup.log"
    params:
        queue = "shortq",
        samtools = config["samtools"]["app"],
        genome_ref_fasta = config["gatk"][config["samples"]]["genome_fasta"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        '{params.samtools} mpileup -a -B -l {input.BED} -f {params.genome_ref_fasta} {input.BAM} | gzip - > {output.PILEUP} 2> {log}'

## A rule to split mutect2 results in pieces 
rule split_Mutect2:
    input:
        Mutect2_vcf = "Mutect2_TvN/{tsample}_Vs_{nsample}_twicefiltered_TvN.vcf.gz",
        vcf_index   = "Mutect2_TvN/{tsample}_Vs_{nsample}_twicefiltered_TvN.vcf.gz.tbi",
    output:
        interval_vcf_bcftools = temp("Mutect2_TvN_oncotator_tmp/{tsample}_Vs_{nsample}_TvN_ON_{interval}_bcftools.vcf.gz"),
        interval_vcf          = temp("Mutect2_TvN_oncotator_tmp/{tsample}_Vs_{nsample}_TvN_ON_{interval}.vcf.gz"),
    params:
        queue    = "shortq",
        bcftools = config["bcftools"]["app"],
        reformat = config["gatk"]["scripts"]["reformat_mutect2"],
        interval = config["gatk"][config["samples"]][config["seq_type"]]["mutect_interval_dir"] + "/{interval}.bed",
    log:
        "logs/Mutect2_TvN_oncotator_tmp/{tsample}_Vs_{nsample}_TvN_ON_{interval}.vcf.log"
    threads : 1
    resources:
        mem_mb = 10240
    shell: 
        '{params.bcftools} view -l 9 -R {params.interval} -o {output.interval_vcf_bcftools} {input.Mutect2_vcf} 2> {log} &&'
        ' python {params.reformat} {output.interval_vcf_bcftools} {output.interval_vcf} 2>> {log}'

# A rule to annotate mutect2 tumor versus normal results with oncotator  
rule oncotator:
    input:
        interval_vcf = "Mutect2_TvN_oncotator_tmp/{tsample}_Vs_{nsample}_TvN_ON_{interval}.vcf.gz",
    output:
        MAF = temp("oncotator_TvN_tmp/{tsample}_Vs_{nsample}_ON_{interval}_annotated_TvN.TCGAMAF"),
    params:
        queue = "shortq",
        oncotator = config["oncotator"]["app"],
        DB    = config["oncotator"][config["samples"]]["DB"],
        ref   = config["oncotator"][config["samples"]]["ref"],
    log:
        "logs/oncotator_TvN_tmp/{tsample}_Vs_{nsample}_ON_{interval}_annotated_TvN.TCGAMAF"
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        '{params.oncotator} --input_format=VCF --output_format=TCGAMAF --tx-mode EFFECT --db-dir={params.DB} {input.interval_vcf} {output.MAF} {params.ref} 2> {log}'


# concatenate oncotator TvN
rule concatenate_oncotator:
    input:
        maf = expand("oncotator_TvN_tmp/{{tsample}}_Vs_{{nsample}}_ON_{mutect_interval}_annotated_TvN.TCGAMAF", mutect_interval=mutect_intervals)
    output:
        concatened_oncotator = temp("oncotator_TvN/{tsample}_Vs_{nsample}_annotated_TvN.TCGAMAF"),
        tmp_list             = temp("oncotator_TvN_tmp/{tsample}_Vs_{nsample}_TvN_oncotator_tmp.list"),
    params:
        queue = "shortq",
        merge = config["oncotator"]["scripts"]["merge_oncotator"],
    threads : 1
    resources:
        mem_mb = 10240
    log:
        "logs/merge_oncotator/{tsample}_Vs_{nsample}_TvN.vcf.log"
    shell :
        "ls -1a oncotator_TvN_tmp/{wildcards.tsample}_Vs_{wildcards.nsample}_ON_*_annotated_TvN.TCGAMAF > oncotator_TvN_tmp/{wildcards.tsample}_Vs_{wildcards.nsample}_TvN_oncotator_tmp.list && "
        "python2.7  {params.merge} {output.tmp_list} {output.concatened_oncotator} 2> {log}"
        
## A rule to simplify oncotator output on tumor vs normal samples
rule oncotator_reformat_TvN:
    input:
        maf = "oncotator_TvN/{tsample}_Vs_{nsample}_annotated_TvN.TCGAMAF"
    output:
        maf = "oncotator_TvN_maf/{tsample}_Vs_{nsample}_TvN_selection.TCGAMAF",
        tsv = temp("oncotator_TvN_tsv/{tsample}_Vs_{nsample}_TvN.tsv"),
    log:
        "logs/oncotator/{tsample}_Vs_{nsample}_TvN_selection.log"
    params:
        queue   = "shortq",
        extract = config["oncotator"]["scripts"]["extract_tumor_vs_normal"]
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        "python2.7 {params.extract} {input.maf} {output.maf} {output.tsv} 2> {log}"

## A rule to cross oncotator output on tumor vs normal samples with pileup information
rule oncotator_with_pileup_TvN:
    input:
        tsv    = "oncotator_TvN_tsv/{tsample}_Vs_{nsample}_TvN.tsv",
        pileup = "pileup_TvN/{tsample}_Vs_{nsample}_TvN.pileup.gz",
    output:
        tsv = temp("oncotator_TvN_tsv_pileup/{tsample}_Vs_{nsample}_TvN_with_pileup.tsv"),
    log:
        "logs/oncotator/{tsample}_Vs_{nsample}_TvN_with_pileup.log"
    params:
        queue = "shortq",
        oncotator_cross_pileup = config["oncotator"]["scripts"]["pileup"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        'python {params.oncotator_cross_pileup} {input.pileup} {input.tsv} {output.tsv}'

## A rule to cross oncotator output on tumor vs normal samples with COSMIC information
rule oncotator_with_COSMIC_TvN:
    input:
        tsv = "oncotator_TvN_tsv_pileup/{tsample}_Vs_{nsample}_TvN_with_pileup.tsv"
    output:
        tsv = "oncotator_TvN_tsv_COSMIC/{tsample}_Vs_{nsample}_TvN_with_COSMIC.tsv"
    log:
        "logs/oncotator/{tsample}_Vs_{nsample}_TvN_with_COSMIC.log"
    params:
        queue = "shortq",
        cross_cosmic    = config["oncotator"]["scripts"]["cosmic_t_n"],
        cosmic_mutation = config["oncotator"][config["samples"]]["cosmic_mutation"],
        cancer_census_oncogene = config["oncotator"][config["samples"]]["cancer_census_oncogene"],
        cancer_census_tumorsupressor = config["oncotator"][config["samples"]]["cancer_census_tumorsupressor"]
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        "python2.7 {params.cross_cosmic} {input.tsv} {output.tsv} {params.cosmic_mutation} {params.cancer_census_oncogene} {params.cancer_census_tumorsupressor} 2> {log}"
