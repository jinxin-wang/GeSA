rule SigProfiler_TvN:
    input:
        input_path = "Mutect2_TvN",
        input_vcf = expand("Mutect2_TvN/{tsample}_vs_{nsample}_twicefiltered_TvN.vcf.gz", zip, tsample=TSAMPLE, nsample=NSAMPLE)
    output:
        out_path = "SigProfiler_TvN",
        SBS96    = f"SigProfiler_TvN/output/SBS/Results.SBS96.{'exome' if config['seq_type'] == 'WES' else 'all'}",
        solution = 'SigProfiler_TvN/SBS_cosmic_fit/Assignment_Solution/Signatures/Assignment_Solution_Signatures.txt',
    log:
        "logs/SigProfiler/SigProfiler_TvN.log"
    params:
        queue       = "shortq",
        SigProfiler = config["SigProfiler"]["script"],
        seq_type    = config["seq_type"],
    threads : 1
    conda: "SigProfiler"
    resources:
        mem_mb = 2048
    shell:
        'python {params.SigProfiler} {params.seq_type} {input.input_path} {output.out_path} > {log};'


rule SigProfiler_Tonly:
    input:
        input_path = "Mutect2_T",
        input_vcf = expand("Mutect2_T/{tsample}_tumor_only_filtered_T.vcf.gz", tsample=TSAMPLE),
    output:
        out_path = "SigProfiler_T",
        SBS96    = f"SigProfiler_T/output/SBS/Results.SBS96.{'exome' if config['seq_type'] == 'WES' else 'all'}",
        solution = 'SigProfiler_T/SBS_cosmic_fit/Assignment_Solution/Signatures/Assignment_Solution_Signatures.txt',
    log:
        "logs/SigProfiler/SigProfiler_Tonly.log"
    params:
        queue       = "shortq",
        SigProfiler = config["SigProfiler"]["script"],
        seq_type    = config["seq_type"],
    threads : 1
    conda: "SigProfiler"
    resources:
        mem_mb = 2048
    shell:
        'python {params.SigProfiler} {params.seq_type} {input.input_path} {output.out_path} > {log};'




