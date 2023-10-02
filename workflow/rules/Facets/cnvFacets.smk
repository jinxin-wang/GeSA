rule cnv_facets:
    input:
        tumor_bam = "bam/{tsample}.nodup.recal.bam",
        tumor_bai = "bam/{tsample}.nodup.recal.bam.bai",
        normal_bam = "bam/{nsample}.nodup.recal.bam",
        normal_bai = "bam/{nsample}.nodup.recal.bam.bai"
    output:
        csv = "cnv_facets/{tsample}_vs_{nsample}.vcf.gz",
        csv_index = "cnv_facets/{tsample}_vs_{nsample}.vcf.gz.tbi"
    log:
        "logs/facets/{tsample}_vs_{nsample}_facets.log"
    params:
        queue = "mediumq",
        cnv_facet = config["cnv_facets"]["app"],
        gnomad_ref = config["gatk"][config["samples"]]["gnomad_ref"],
        cval = config["cnv_facets"][config["samples"]]["cval"],
        ref  = config["cnv_facets"][config["samples"]]["ref"],
        out_pattern = "{tsample}_vs_{nsample}"
    threads : 16
    resources:
        mem_mb = 102400
    shell:
        'cd cnv_facets; {params.cnv_facet} --snp-nprocs {threads} --gbuild {params.ref} --cval {params.cval} --snp-vcf {params.gnomad_ref} -t ../{input.tumor_bam} -n ../{input.normal_bam} --out {params.out_pattern}'
 
