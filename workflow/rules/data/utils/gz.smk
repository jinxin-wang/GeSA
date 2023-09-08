rule compr_with_gzip_abstract:
    input:
        "input_file_name",
    output:
        "output_file_name",
    params:
        queue = "shortq",
    threads : 1
    resources:
        mem_mb = 10240
    log:
        lambda wildcards, output: "logs/%s.log"%output , 
    shell :
        " gzip -c {input} > {output}  2> {log} "
