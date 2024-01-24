# A rule to generate a bed from mutect2 vcf, on tumor only with panel of normal
rule get_variant_bed_tumor_only_pon:
    input:
        Mutect2_vcf = "Mutect2_Tp/{tsample}_PON_{panel_of_normal}_twicefiltered_Tp.vcf.gz",
        Mutect2_vcf_index = "Mutect2_Tp/{tsample}_PON_{panel_of_normal}_twicefiltered_Tp.vcf.gz.tbi",
    output:
        BED = temp("variant_bed_Tp/{tsample}_PON_{panel_of_normal}_Tp.bed")
    log:
        "logs/variant_bed_Tp/{tsample}_PON_{panel_of_normal}_Tp.bed.log"
    params:
        queue = "shortq",
        vcf2bed = config["vcf2bed"]["app"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        'zcat {input.Mutect2_vcf} | python2 {params.vcf2bed} - > {output.BED} 2> {log}'

# Run samtools mpileup, on tumor only with panel of normal
rule samtools_mpileup_tumor_only_pon:
    input:
        BED = "variant_bed_Tp/{tsample}_PON_{panel_of_normal}_Tp.bed",
        BAM = "bam/{tsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam",
        BAI = "bam/{tsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam.bai"
    output:
        PILEUP = temp("pileup_Tp/{tsample}_PON_{panel_of_normal}_Tp.pileup.gz")
    log:
        "logs/pileup_Tp/{tsample}_PON_{panel_of_normal}_Tp.pileup.log"
    params:
        queue = "shortq",
        samtools = config["samtools"]["app"],
        genome_ref_fasta = config["gatk"][config["samples"]]["genome_fasta"],
    threads : 8
    resources:
        mem_mb = 20480
    shell:
        '{params.samtools} mpileup -@ {threads} -a -B -l {input.BED} -f {params.genome_ref_fasta} {input.BAM} | gzip - > {output.PILEUP} 2> {log}'
        
## A rule to split mutect2 results in pieces 
rule split_Mutect2_tumor_only_pon:
    input:
        Mutect2_vcf = "Mutect2_Tp/{tsample}_PON_{panel_of_normal}_twicefiltered_Tp.vcf.gz",
        vcf_index = "Mutect2_Tp/{tsample}_PON_{panel_of_normal}_twicefiltered_Tp.vcf.gz.tbi",
    output:
        interval_vcf_bcftools = temp("Mutect2_Tp_oncotator_tmp/{tsample}_PON_{panel_of_normal}_Tp_ON_{interval}_bcftools.vcf.gz"),
        interval_vcf          = temp("Mutect2_Tp_o)ncotator_tmp/{tsample}_PON_{panel_of_normal}_Tp_ON_{interval}.vcf.gz")
    params:
        queue = "shortq",
        bcftools = config["bcftools"]["app"],
        reformat = config["gatk"]["scripts"]["reformat_mutect2"],
        interval = config["gatk"][config["samples"]][config["seq_type"]]["mutect_interval_dir"] + "/{interval}.bed"
    log:
        "logs/Mutect2_Tp_oncotator_tmp/{tsample}_PON_{panel_of_normal}_Tp_ON_{interval}.vcf.log"
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        '{params.bcftools} view -l 9 -R {input.interval} -o {output.interval_vcf_bcftools} {input.Mutect2_vcf} 2> {log}  &&'
        ' python {params.reformat_script} {output.interval_vcf_bcftools} {output.interval_vcf} 2>> {log}'        
        
# A rule to annotate mutect2 tumor only with panel of normal results with oncotator 
rule oncotator_tumor_only_pon:
    input:
        interval_vcf = "Mutect2_Tp_oncotator_tmp/{tsample}_PON_{panel_of_normal}_Tp_ON_{interval}.vcf.gz"
    output:
        MAF = temp("oncotator_Tp_tmp/{tsample}_PON_{panel_of_normal}_ON_{interval}_annotated_Tp.TCGAMAF")
    params:
        queue = "shortq",
        oncotator = config["oncotator"]["app"],
        DB    = config["oncotator"][config["samples"]]["DB"],
        ref   = config["oncotator"][config["samples"]]["ref"],
    log:
        "logs/oncotator_Tp_tmp/{tsample}_PON_{panel_of_normal}_ON_{interval}_annotated_Tp.TCGAMAF"
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        'oncotator --input_format=VCF --output_format=TCGAMAF --tx-mode EFFECT --db-dir={input.ONCOTATOR_DB} {input.interval_vcf} {output.MAF} {params.ref} 2> {log}'

# concatenate oncotator T_only_pon
rule concatenate_oncotator_tumor_only_pon:
    input:
        maf = expand("oncotator_Tp_tmp/{{tsample}}_PON_{{panel_of_normal}}_ON_{mutect_interval}_annotated_Tp.TCGAMAF", mutect_interval=mutect_intervals)
    output:
        concatened_oncotator = "oncotator_Tp/{tsample}_PON_{panel_of_normal}_annotated_Tp.TCGAMAF",
        tmp_list = temp("oncotator_Tp_tmp/{tsample}_PON_{panel_of_normal}_Tp_oncotator_tmp.list"),
    params:
        queue = "shortq",
        merge = config["oncotator"]["scripts"]["merge_oncotator"],
    threads : 1
    resources:
        mem_mb = 10240
    log:
        "logs/merge_oncotator/{tsample}_PON_{panel_of_normal}_annotated_Tp.log"
    shell :
        "ls -1a oncotator_Tp_tmp/{wildcards.tsample}_PON_{wildcards.panel_of_normal}_ON_*_annotated_Tp.TCGAMAF > oncotator_Tp_tmp/{wildcards.tsample}_PON_{wildcards.panel_of_normal}_Tp_oncotator_tmp.list && "
        "python2.7  {params.merge_oncotator} {output.tmp_list} {output.concatened_oncotator} 2> {log}" 

## A rule to simplify oncotator output on tumor only samples with pon
rule oncotator_reformat_tumor_only_pon:
    input:
        maf="oncotator_Tp/{tsample}_PON_{panel_of_normal}_annotated_Tp.TCGAMAF"
    output:
        maf = "oncotator_Tp_maf/{tsample}_PON_{panel_of_normal}_Tp_selection.TCGAMAF",
        tsv = temp("oncotator_Tp_tsv/{tsample}_PON_{panel_of_normal}_Tp.tsv")
    log:
        "logs/oncotator/{tsample}_PON_{panel_of_normal}_Tp_selection.log"
    params:
        queue = "shortq",
        extract = config["oncotator"]["scripts"]["extract_tumor_only"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        'python2.7 {params.extract} {input.maf} {output.maf} {output.tsv} 2> {log}'

## A rule to simplify oncotator output on tumor only samples with pon
rule oncotator_with_pileup_tumor_only_pon:
    input:
        tsv = "oncotator_Tp_tsv/{tsample}_PON_{panel_of_normal}_Tp.tsv",
        pileup = "pileup_Tp/{tsample}_PON_{panel_of_normal}_Tp.pileup.gz"
    output:
        tsv = temp("oncotator_Tp_tsv_pileup/{tsample}_PON_{panel_of_normal}_Tp_with_pileup.tsv")
    log:
        "logs/oncotator/{tsample}_PON_{panel_of_normal}_Tp_with_pileup.log"
    params:
        queue = "shortq",
        oncotator_cross_pileup = config["oncotator"]["scripts"]["pileup"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        'python {params.oncotator_cross_pileup} {input.pileup} {input.tsv} {output.tsv}'
        
## A rule to simplify oncotator output on tumor only samples with pon
rule oncotator_with_COSMIC_tumor_only_pon:
    input:
        tsv = "oncotator_Tp_tsv_pileup/{tsample}_PON_{panel_of_normal}_Tp_with_pileup.tsv"
    output:
        tsv = "oncotator_Tp_tsv_COSMIC/{tsample}_PON_{panel_of_normal}_Tp_with_COSMIC.tsv"
    log:
        "logs/oncotator/{tsample}_PON_{panel_of_normal}_Tp_with_COSMIC.log"
    params:
        queue = "shortq",
        cross_cosmic    = config["oncotator"]["scripts"]["cosmic_t_only"],
        cosmic_mutation = config["oncotator"][config["samples"]]["cosmic_mutation"],
        cancer_census_oncogene = config["oncotator"][config["samples"]]["cancer_census_oncogene"],
        cancer_census_tumorsupressor = config["oncotator"][config["samples"]]["cancer_census_tumorsupressor"]
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        'python2.7 {params.oncotator_cross_cosmic}  {input.tsv} {output.tsv} {params.cosmic_mutation} {params.cancer_census_oncogene} {params.cancer_census_tumorsupressor} 2> {log}'
