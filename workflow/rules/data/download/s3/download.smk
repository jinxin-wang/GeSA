rule amazon_s3_download_datasets:
    input:
        config = config["S3_CONFIG_FILE"],
    output:
        storage_path = directory(config["STORAGE_PATH"]),
    params:
        s3cmd  = config["S3_APP"],
        dataset= config["S3_dataset"],
    threads: 4
    resources:
        queue  = "mediumq",
        mem_mb = 10240,
        disk_mb  = dataset_size * 1024,
        time_min = dataset_size * 2,
    log:
        out = f"logs/data/download/s3/amazon_s3_download_datasets.log"
    run:
        cmd = f"mkdir -p {output.storage_path} ;
                {params.s3cmd} -c {input.config} get --recursive s3://{params.dataset}/ {output.storage_path} ; "
        
        logging.info(f"executing S3 command: {cmd}")
        
        os.system(cmd)
