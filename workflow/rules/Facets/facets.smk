rule facets_snp_pilleup:
    input:
        TUMOR_BAM = "bam/{tsample}.nodup.recal.bam",
        NORMAL_BAM = "bam/{nsample}.nodup.recal.bam"
    output:
        CSV = "facets/{tsample}_vs_{nsample}_facets.csv.gz"
    log:
        "logs/facets/{tsample}_vs_{nsample}_facets.log"
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
        CSV="facets/{tsample}_vs_{nsample}_facets.csv.gz"
    output:
        PDF =  "facets/{tsample}_vs_{nsample}_facets_cval500.pdf",
        RDATA = "facets/{tsample}_vs_{nsample}_facets_cval500.RData"
    log:
        "logs/facets/{tsample}_vs_{nsample}_facets_graph.log"
    params:
        queue = "shortq",
        R = config["R"]["Rscript4.3"],
        facet_graph = config["R"]["scripts"]["facet_graph"],
	facet_unmutch_normal = config["facet_unmutch_normal"],
        facet_cell_lines = config["facet_cell_lines"]
    threads : 4
    resources:
        mem_mb = 40960 if config['seq_type'] == 'WES' else 102400,
    shell:
        '{params.R} {params.facet_graph} {input.CSV} {params.facet_unmutch_normal} {params.facet_cell_lines}'

rule facet_purity_ploidy:
    input:
        RDATA = "facets/{tsample}_vs_{nsample}_facets_cval500.RData"
    output:
        CSV   =  "facets/{tsample}_vs_{nsample}_purity_ploidy.csv",
    log:
        "logs/facets/{tsample}_vs_{nsample}_purity_ploidy.log"
    params:
        queue = "shortq",
        R = config["R"]["Rscript4.3"],
        facet_purity = config["R"]["scripts"]["facet_purity"],
    threads : 1
    resources:
        mem_mb = 512 if config['seq_type'] == 'WES' else 1024,
    shell:
        '{params.R} {params.facet_purity} -f {input.RDATA} -o {output.CSV} '

