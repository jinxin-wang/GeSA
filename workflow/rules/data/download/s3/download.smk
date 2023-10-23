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
        disk_mb= ( int(config["S3_DATASET_SIZE"].split('.')[0]) + 1 )*1024,
        time_min = ( int(config["S3_DATASET_SIZE"].split('.')[0]) + 1 ) * 2,
    log:
        out = f"logs/data/download/s3/amazon_s3_download_datasets.log"
    run:
        if sys.version_info.major < 3:
            logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

        logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)

        cmd = f"mkdir -p {output.storage_path} ; cd {output.storage_path} ; {params.s3cmd} -c {input.config} get s3://{params.dataset}/ --recursive "
        logging.info(f"executing S3 command: {cmd}")
        os.system(cmd)
