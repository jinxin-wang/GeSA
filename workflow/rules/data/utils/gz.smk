rule compr_with_gzip_abstract:
    input:
        "input_file_name",
    output:
        "output_file_name",
    params:
        # queue = "shortq",
        queue = lambda w,input: "shortq" if os.path.getsize(input[0])/1024/1024/1024 < 100  else  "mediumq",
        gz    = config["gz"]["bgzip"],
    threads : 1
    resources:
        mem_mb = 10240
    shell :
        # " gzip -c {input} > {output} "
        "{params.gz} -c {input} > {output} "
