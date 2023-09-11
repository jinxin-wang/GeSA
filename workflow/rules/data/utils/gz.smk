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
    shell :
        " gzip -c {input} > {output} "
