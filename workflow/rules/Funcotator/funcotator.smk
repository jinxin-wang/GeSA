## https://gatk.broadinstitute.org/hc/en-us/articles/360035889931-Funcotator-Information-and-Tutorial

rule mut_funcotator_TvN:
    input:
        vcf  = "Mutect2_TvN/{tsample}_vs_{nsample}_twicefiltered_TvN.vcf.gz",
        index= "Mutect2_TvN/{tsample}_vs_{nsample}_twicefiltered_TvN.vcf.gz.tbi",
    output:
        maf  = "mut_funcotator_TvN/{tsample}_vs_{nsample}.funcotated.maf",
    log:
        "logs/mut_funcotator_TvN/{tsample}_vs_{nsample}.log" 
    conda:
        "gatk"
    params:
        queue = "shortq",
        gatk  = config["gatk"]["app"],
        ref   = config[""],
        db    = config["gatk"]["funcotator"]["database"], # funcotator_dataSources.v1.2.20180329
    threads: 1
    resources:
        queue  = "shortq",
        mem_mb = 8000,
    shell:
        """
        gatk Funcotator \
            --variant {input.vcf} \
            --reference {params.ref} \
            --ref-version hg19 \
            --data-sources-path {params.db} \
            --output {output.maf} \
            --output-file-format MAF 2> {log}
        """

use rule mut_funcotator_TvN as mut_funcotator_T with:
    input:
        vcf  = "Mutect2_T/{tsample}_twicefiltered_TvN.vcf.gz",
        index= "Mutect2_T/{tsample}_twicefiltered_TvN.vcf.gz.tbi",
    output:
        maf  = "mut_funcotator_T/{tsample}.funcotated.maf",
    log:
        "logs/mut_funcotator_T/{tsample}.log" 
        
