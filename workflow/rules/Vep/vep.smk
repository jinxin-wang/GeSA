# https://www.ensembl.org/info/docs/tools/vep/script/vep_options.html#basic
# https://www.ensembl.org/info/docs/tools/vep/online/VEP_web_documentation.pdf
rule mut_vep_TvN:
    input:
        vcf  = "Mutect2_TvN/{tsample}_vs_{nsample}_twicefiltered_TvN.vcf.gz",
        index= "Mutect2_TvN/{tsample}_vs_{nsample}_twicefiltered_TvN.vcf.gz.tbi",
    output:
        vcf  = "mut_vep_TvN/{tsample}_vs_{nsample}.vcf",
    log:
        "logs/mut_vep_TvN/{tsample}_vs_{nsample}.log" 
    conda:
        "metaprism_perl"
    params:
        queue  = "shortq",
        vep    = config["vep"]["script"],
        cache  = config["vep"]["cache"],
        species= "homo_sapiens" if config["samples"] == "human" else "mus_musculus",
    threads: 1
    resources:
        queue  = "shortq",
        mem_mb = 8000,
    shell:
        """
        {params.vep} --input_file {input.vcf} \
            --dir {params.cache} \
            --cache \
            --canonical \
            --format vcf \
            --offline \
            --vcf \
            --no_progress \
            --no_stats \
            --af_gnomad \
            --appris \
            --sift b \
            --polyphen b \
            --biotype \
            --buffer_size 5000 \
            --hgvs \
            --species {params.species} \
            --symbol \
            --transcript_version \
            --output_file {output.vcf} \
            --warning_file {log}
        """

use rule mut_vep_TvN as mut_vep_T with:
    input:
        vcf  = "Mutect2_T/{tsample}_twicefiltered_T.vcf.gz",
        index= "Mutect2_T/{tsample}_twicefiltered_T.vcf.gz.tbi",
    output:
        vcf  = "mut_vep_T/{tsample}.vcf",
    log:
        "logs/mut_vep_T/{tsample}.log" 


use rule mut_vep_TvN as cnv_vep_TvN with:
    input:
        csv = "cnv_facets/{tsample}_vs_{nsample}.vcf.gz",
        index = "cnv_facets/{tsample}_vs_{nsample}.vcf.gz.tbi"
    output:
        vcf  = "cnv_vep_TvN/{tsample}_vs_{nsample}.vcf",
    log:
        "logs/cnv_vep_TvN/{tsample}_vs_{nsample}.log" 




        
