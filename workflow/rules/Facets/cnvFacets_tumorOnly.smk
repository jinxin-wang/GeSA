rule cnv_facets_tumorOnly:
    input:
        tumor_bam = "bam/{tsample}.nodup.recal.bam",
        tumor_bai = "bam/{tsample}.nodup.recal.bam.bai",
    output:
        csv = "cnv_facets_tumorOnly/{tsample}_Vs_unmatchedNormal.vcf.gz",
        csv_index = "cnv_facets_tumorOnly/{tsample}_Vs_unmatchedNormal.vcf.gz.tbi"
    log:
        "logs/cnv_facets_tumorOnly/{tsample}_Vs_unmatchedNormal_facets.log"
    params:
        queue = "mediumq",
        cnv_facet = config["cnv_facets"]["app"],
        gnomad_ref = config["gatk"][config["samples"]]["gnomad_ref"],
        cval = config["cnv_facets"][config["samples"]]["cval"],
        ref  = config["cnv_facets"][config["samples"]]["ref"],
        out_pattern = "{tsample}_Vs_unmatchedNormal",
        normal_bam = config["facet_snp_pileup"]["unmatched_normal_bam"],
        normal_bai = config["facet_snp_pileup"]["unmatched_normal_bai"]
    threads : 4
    resources:
        mem_mb = 50000
    shell:
        'cd cnv_facets_tumorOnly; {params.cnv_facet} --snp-nprocs {threads} --gbuild {params.ref} --unmatched --cval {params.cval} --snp-vcf {params.gnomad_ref} -t ../{input.tumor_bam} -n {params.normal_bam} --out {params.out_pattern}'
 
