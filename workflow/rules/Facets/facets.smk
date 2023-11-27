rule facets_snp_pilleup:
    input:
        TUMOR_BAM = "bam/{tsample}.nodup.recal.bam",
        NORMAL_BAM = "bam/{nsample}.nodup.recal.bam"
    output:
        CSV = "facets/{tsample}_Vs_{nsample}_facets.csv.gz"
    log:
        "logs/facets/{tsample}_Vs_{nsample}_facets.log"
    params:
        queue = "mediumq",
        snp_pileup = config["facet_snp_pileup"]["app"],
        gnomad_ref = config["facet_snp_pileup"][config["samples"]]["facet_ref"],
    threads : 1
    resources:
        mem_mb = 10240
    shell:
    	'{params.snp_pileup} -g --min-map-quality=55 --min-base-quality=20 --min-read-counts=5,5 {params.gnomad_ref} {output.CSV} {input.NORMAL_BAM} {input.TUMOR_BAM}'
	# '{params.snp_pileup} -g --min-map-quality=55 --min-base-quality=20 --max-depth=200 --min-read-counts=15,15 {params.gnomad_ref} {output.CSV} {input.NORMAL_BAM} {input.TUMOR_BAM}'

#A rule to draw facets graphs
rule facet_graph:
    input:
        CSV="facets/{tsample}_Vs_{nsample}_facets.csv.gz"
    output:
        PDF =  "facets/{tsample}_Vs_{nsample}_facets_cval500.pdf",
        RDATA = "facets/{tsample}_Vs_{nsample}_facets_cval500.RData"
    log:
        "logs/facets/{tsample}_Vs_{nsample}_facets_graph.log"
    params:
        queue = "shortq",
        R = config["R"]["Rscript4.3"],
        facet_graph = config["R"]["scripts"]["facet_graph"],
    threads : 4
    resources:
        mem_mb = 40960
    shell:
        '{params.R} {params.facet_graph} {input.CSV}'
