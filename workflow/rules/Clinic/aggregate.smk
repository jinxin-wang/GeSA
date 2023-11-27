rule aggregate_alterations:
    log:
        "%s/aggregate_alterations_across_modalities_{cohort}.log" % L_FOLDER
    input:
        # bio = lambda w: config["data"]["bio"][w.cohort],
        cln = "",
        cna = "",
        fus = "",
        # msi = lambda w: config["data"]["msi"][w.cohort],
        mut = "",
        # tmb = lambda w: config["data"]["tmb"][w.cohort],
        # exp_arv7 = lambda w: config["data"]["exp_arv7"][w.cohort],
        gen = "",
        drug = "",
        target_bed = "",
    conda: "metaprism_r"
    output:
        best="%s/alterations/aggregated_alterations_{cohort}.tsv" % R_FOLDER,
        all="%s/alterations/aggregated_alterations_{cohort}_all.tsv" % R_FOLDER,
    params:
        partition = "shortq"
    resources:
        mem_mb = 10240,
    threads: 1
    shell:
        """
        Rscript workflow/rules/Clinic/scripts/01.1_aggregate_alterations_across_modalities.R \
            --cln {input.cln} \
            --cna {input.cna} \
            --fus {input.fus} \
            --mut {input.mut} \
            --target_bed {input.target_bed} \
            --drug {input.drug} \
            --output_best {output.best} \
            --output_all {output.all} \
            --log {log}
        """
