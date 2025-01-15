# Process VCF file
rule facets_suite:
    input:
        TUMOR_BAM = "bam/{tsample}.nodup.recal.bam",
        NORMAL_BAM= "bam/{nsample}.nodup.recal.bam",
    output:
        table = "facets_suites/{tsample}_vs_{nsample}.snp_pileup.gz",
    params:
        queue = "shortq",
        prefix= "facets_suites/{tsample}_vs_{nsample}",
        wrapper = config["facets_suites"]["snp_pileup_wrapper"], 
        snp_pileup = config["facet_snp_pileup"]["app"],
        gnomad_ref = config["facet_snp_pileup"][config["samples"]]["facet_ref"],
    log: 
        "logs/facets_suites/{tsample}_vs_{nsample}.log",
    conda: 
        "rfacets"
    threads: 1
    resources:
        queue = "shortq",
        mem_mb= 10240,
    shell:
        """
        mkdir -p facets_suites ;
        Rscript {params.wrapper} \
            --snp-pileup-path {params.snp_pileup} \
            --vcf-file {params.gnomad_ref}  \
            --normal-bam {input.NORMAL_BAM} \
            --tumor-bam {input.TUMOR_BAM}   \
            --output-prefix {params.prefix} 
        """
