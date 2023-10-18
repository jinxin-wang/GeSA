rule backup_storage_download_datasets:
    output:
        storage_path = directory(config["STORAGE_PATH"]),
    params:
        dataset= config["CLUSTER_STORAGE"],
    threads: 4
    resources:
        queue  = "longq",
        mem_mb = 10240,
    log:
        out = f"logs/download/ftp/ftp_download_datasets.log"
    run:
        if sys.version_info.major < 3:
            logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

        logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)

        mkdir_cmd = f"mkdir -p {output.storage_path} "
        download_cmd = f"rsync -avh --progress {params.dataset} {output.storage_path}"
        cmd = f"{mkdir_cmd} ; {download_cmd} "
        logging.info(f"executing ftp command: {cmd}")
        os.system(cmd)
