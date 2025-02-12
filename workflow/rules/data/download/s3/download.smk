if config["S3_CONFIG_FILE"] != None : 
    rule amazon_s3_download_datasets:
        input:
            config = config["S3_CONFIG_FILE"],
        output:
            storage_path = directory(config["STORAGE_PATH"]),
        params:
            s3cmd = config["S3_APP"],
            path  = config["S3_PATH"],
        threads: 1
        resources:
            queue  = "mediumq",
            mem_mb = 10240,
            disk_mb  = dataset_size * 1024,
            time_min = dataset_size * 4,
        log:
            out = "logs/data/download/s3/amazon_s3_download_datasets.log"
        benchmark: 
            "logs/benchmark/data/download/s3/amazon_s3_download_datasets.tsv"
        run:
            logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)

            if sys.version_info.major < 3:
                logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

            cmd = f"mkdir -p {output.storage_path} ; {params.s3cmd} -c {input.config} get --recursive {params.path} {output.storage_path} ; "
                
            logging.info(f"executing S3 command: {cmd}")
                
            os.system(cmd)


else :
    rule amazon_aws_download_datasets:
        input:
            AWS_CONFIG_FILE             = config["AWS_CONFIG_FILE"],
            AWS_SHARED_CREDENTIALS_FILE = config["AWS_SHARED_CREDENTIALS_FILE"],
        output:
            storage_path = directory(config["STORAGE_PATH"]),
        params:
            aws  = config["AWS_APP"],
            path = config["S3_PATH"],
        threads: 1
        resources:
            queue  = "mediumq",
            mem_mb = 10240,
            disk_mb  = dataset_size * 1024,
            time_min = dataset_size * 4,
        log:
            out = "logs/data/download/s3/amazon_aws_download_datasets.log"
        benchmark: 
            "logs/benchmark/data/download/s3/amazon_aws_download_datasets.tsv"
        run:
            logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)

            if sys.version_info.major < 3:
                logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

            cmd = f"mkdir -p {output.storage_path} ; export AWS_CONFIG_FILE=\"{input.AWS_CONFIG_FILE}\" ; export AWS_SHARED_CREDENTIALS_FILE=\"{input.AWS_SHARED_CREDENTIALS_FILE}\" ; {params.aws} s3 cp {params.path} {output.storage_path} --recursive ; "
                
            logging.info(f"executing S3 command: {cmd}")
                
            os.system(cmd)
