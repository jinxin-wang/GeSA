rule ftp_download_datasets:
    output:
        storage_path = directory(config["STORAGE_PATH"]),
    params:
        ftp    = config["FTP_APP"],
        user   = config["FTP_USERNAME"],
        passwd = config["FTP_PASSWORD"],
        host   = config["FTP_HOST"],
        dataset= config["FTP_DATASET"],
    threads: 4
    resources:
        queue  = "longq",
        mem_mb = 10240,
        disk_mb  = dataset_size * 1024,
        time_min = dataset_size * 2,
    log:
        out = f"logs/download/ftp/ftp_download_datasets.log"
    run:
        logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)

        if sys.version_info.major < 3:
            logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

        mkdir_cmd = f"mkdir -p {output.storage_path} "
        download_cmd = f"{params.ftp} -c \"set ftp:ssl-allow no; open -u {params.user}, {params.passwd} {params.host} ; get -O {output.storage_path} {params.dataset} ;\" "
        cmd = f"{mkdir_cmd} ; {download_cmd} "
        
        logging.info(f"executing ftp command: {cmd}")
        
        os.system(cmd)
