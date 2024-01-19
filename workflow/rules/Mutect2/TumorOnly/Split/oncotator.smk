# A rule to generate a bed from mutect2 vcf, on tumor only 
rule get_variant_bed_tumor_only:
    input:
        Mutect2_vcf = "Mutect2_T/{tsample}_tumor_only_twicefiltered_T.vcf.gz",
        Mutect2_vcf_index = "Mutect2_T/{tsample}_tumor_only_twicefiltered_T.vcf.gz.tbi"
    output:
        BED = "variant_bed_T/{tsample}_tumor_only_T.bed"
    log:
        "logs/variant_bed_T/{tsample}_tumor_only_T.bed.log"
    params:
        queue = "shortq",
        vcf2bed = config["vcf2bed"]["app"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        'zcat {input.Mutect2_vcf} | python2 {params.vcf2bed} - > {output.BED} 2> {log}'
        
# Run samtools mpileup, on tumor only 
rule samtools_mpileup_tumor_only:
    input:
        BED = "variant_bed_T/{tsample}_tumor_only_T.bed",
        BAM = "bam/{tsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam",
        BAI = "bam/{tsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam.bai"
    output:
        PILEUP = "pileup_T/{tsample}_tumor_only_T.pileup.gz"
    log:
        "logs/pileup_T/{tsample}_tumor_only_T.pileup.log"
    params:
        queue = "shortq",
        samtools = config["samtools"]["app"],
        genome_ref_fasta = config["gatk"][config["samples"]]["genome_fasta"],
    threads : 4
    resources:
        mem_mb = 10240
    shell:
        '{params.samtools} mpileup -a -B -l {input.BED} -f {params.genome_ref_fasta} {input.BAM} | gzip - > {output.PILEUP} 2> {log}'
 
## A rule to split mutect2 results in pieces 
rule split_Mutect2_tumor_only:
    input:
        Mutect2_vcf = "Mutect2_T/{tsample}_tumor_only_twicefiltered_T.vcf.gz",
        vcf_index   = "Mutect2_T/{tsample}_tumor_only_twicefiltered_T.vcf.gz.tbi",
    output:
        interval_vcf_bcftools = temp("Mutect2_T_oncotator_tmp/{tsample}_tumor_only_T_ON_{interval}_bcftools.vcf.gz"),
        interval_vcf          = temp("Mutect2_T_oncotator_tmp/{tsample}_tumor_only_T_ON_{interval}.vcf.gz")
    params:
        queue = "shortq",
        python  = config["python"]["2.7"],
        bcftools = config["bcftools"]["app"],
        reformat = config["gatk"]["scripts"]["reformat_mutect2"],
        interval = config["gatk"][config["samples"]][config["seq_type"]]["mutect_interval_dir"] + "/{interval}.bed"
    log:
        "logs/Mutect2_T_oncotator_tmp/{tsample}_tumor_only_T_ON_{interval}.vcf.log"
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        '{params.bcftools} view -l 9 -R {params.interval} -o {output.interval_vcf_bcftools} {input.Mutect2_vcf} 2> {log}  &&' 
        '{params.python} {params.reformat} {output.interval_vcf_bcftools} {output.interval_vcf} 2>> {log}'  
 
# A rule to annotate mutect2 tumor only results with oncotator 
rule oncotator_tumor_only:
    input:
        interval_vcf = "Mutect2_T_oncotator_tmp/{tsample}_tumor_only_T_ON_{interval}.vcf.gz",
    output:
        MAF = temp("oncotator_T_tmp/{tsample}_tumor_only_ON_{interval}_annotated_T.TCGAMAF")
    params:
        oncotator = config["oncotator"]["app"],
        queue = "shortq",
        DB    = config["oncotator"][config["samples"]]["DB"],
        ref   = config["oncotator"][config["samples"]]["ref"],
    log:
        "logs/oncotator_T_tmp/{tsample}_ON_{interval}_tumor_only_annotated_T.TCGAMAF"
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        '{params.oncotator} --input_format=VCF --output_format=TCGAMAF --tx-mode EFFECT --db-dir={params.DB} {input.interval_vcf} {output.MAF} {params.ref} 2> {log}'

# concatenate oncotator T_only
rule concatenate_oncotator_tumor_only:
    input:
        maf = expand("oncotator_T_tmp/{{tsample}}_tumor_only_ON_{mutect_interval}_annotated_T.TCGAMAF", mutect_interval=mutect_intervals)
    output:
        concatened_oncotator = "oncotator_T/{tsample}_tumor_only_annotated_T.TCGAMAF",
        tmp_list = temp("oncotator_T_tmp/{tsample}_T_oncotator_tmp.list")
    params:
        queue = "shortq",
        merge = config["oncotator"]["scripts"]["merge_oncotator"],
    threads : 1
    resources:
        mem_mb = 10240
    log:
        "logs/merge_oncotator/{tsample}_tumor_only_annotated_T.log"
    shell :
        "ls -1a oncotator_T_tmp/{wildcards.tsample}_tumor_only_ON_*_annotated_T.TCGAMAF > oncotator_T_tmp/{wildcards.tsample}_T_oncotator_tmp.list && "
        "python2.7  {params.merge} {output.tmp_list} {output.concatened_oncotator} 2> {log}" 

## A rule to simplify oncotator output on tumor only samples
rule oncotator_reformat_tumor_only:
    input:
        maf="oncotator_T/{tsample}_tumor_only_annotated_T.TCGAMAF"
    output:
        maf ="oncotator_T_maf/{tsample}_tumor_only_T_selection.TCGAMAF",
        tsv ="oncotator_T_tsv/{tsample}_tumor_only_T.tsv"
    log:
        "logs/oncotator/{tsample}_tumor_only_T_selection.log"
    params:
        queue   = "shortq",
        extract = config["oncotator"]["scripts"]["extract_tumor_only"],
        python  = config["python"]["2.7"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        '{params.python} {params.extract} {input.maf} {output.maf} {output.tsv} 2> {log}'

## A rule to simplify oncotator output on tumor only samples
rule oncotator_with_pileup_tumor_only:
    input:
        tsv = "oncotator_T_tsv/{tsample}_tumor_only_T.tsv",
        pileup = "pileup_T/{tsample}_tumor_only_T.pileup.gz"
    output:
        tsv = "oncotator_T_tsv_pileup/{tsample}_tumor_only_T_with_pileup.tsv"
    log:
        "logs/oncotator/{tsample}_tumor_only_T_selection_with_pileup.log"
    params:
        queue = "shortq",
        oncotator_cross_pileup = config["oncotator"]["scripts"]["pileup"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
        'python {params.oncotator_cross_pileup} {input.pileup} {input.tsv} {output.tsv}'

## A rule to simplify oncotator output on tumor only samples
rule oncotator_with_COSMIC_tumor_only:
    input:
        tsv = "oncotator_T_tsv_pileup/{tsample}_tumor_only_T_with_pileup.tsv"
    output:
        tsv = "oncotator_T_tsv_COSMIC/{tsample}_tumor_only_T_with_COSMIC.tsv"
    log:
        "logs/oncotator/{tsample}_tumor_only_T_selection_with_COSMIC.log"
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
        'python2.7 {params.cross_cosmic}  {input.tsv} {output.tsv} {params.cosmic_mutation} {params.cancer_census_oncogene} {params.cancer_census_tumorsupressor} 2> {log}'

use rule compr_with_gzip_abstract as oncotator_reformat_gzip_Tonly with:
    input:
        "oncotator_T_maf/{tsample}_tumor_only_T_selection.TCGAMAF",
    output:
        "oncotator_T_maf/{tsample}_tumor_only_T_selection.TCGAMAF.gz",

use rule compr_with_gzip_abstract as COSMIC_gzip_Tonly with:
    input:
        "oncotator_T_tsv_COSMIC/{tsample}_tumor_only_T_with_COSMIC.tsv"
    output:
        "oncotator_T_tsv_COSMIC/{tsample}_tumor_only_T_with_COSMIC.tsv.gz"
