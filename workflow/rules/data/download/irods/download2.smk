import os

if os.path.isfile(config["iRODS_datasets_metadata"]):
    rule irods_metadata_download:
        input:
            meta  = config["iRODS_datasets_metadata"],
        output:
            opath = directory(config["STORAGE_PATH"]),
        params:
            sid   = config["iRODS_METADATA_SAMPLE_ID"],
            cpath = config["iRODS_METADATA_PATH"],
        threads: 1
        resources:
            queue  = "shortq",
            mem_mb = 10240,
            disk_mb  = dataset_size * 1024,
            time_min = dataset_size,
        log:
            out = "logs/data/download/irods/irods_metadata_download.log"
        benchmark:
            "logs/benchmark/data/download/irods/irods_metadata_download.tsv"
        shell:
            "module load python ; python3.9 workflow/rules/data/download/scripts/irods_metadata_download.py --meta {input.meta} --opath {output.opath} --sid {params.sid} --cpath {params.cpath} ; "

elif os.path.isfile(config["iRODS_sample_bilan"]):
    rule irods_query_datasets:
        input:
            ibilan = config["iRODS_sample_bilan"],
        output:
            obilan = "config/datasets_query_bilan.tsv",
        params:
            project_names  = config["PROJECT_NAMES"],
            bilan_query_key  = config["iRODS_BILAN_QUERY_KEY"],
            dataset_query_key= config["iRODS_DATASET_QUERY_KEY"],
            bilan_cquery_keys   = config["iRODS_bilan_cquery_keys"],
            dataset_cquery_keys = config["iRODS_dataset_cquery_keys"],
        threads: 1
        resources:
            queue  = "shortq",
            mem_mb = 10240,
        log:
            out = "logs/data/download/irods/irods_query_datasets.log"
        benchmark:
            "logs/benchmark/data/download/irods/irods_query_datasets.tsv"
        shell:
            "module load python ; python3.9 workflow/rules/data/download/scripts/irods_query_datasets.py --ibilan {input.ibilan} --obilan {output.obilan} --project_names {params.project_names} --bilan_query_key {params.bilan_query_key} --dataset_query_key {params.dataset_query_key} --bilan_cquery_keys {params.bilan_cquery_keys} --dataset_cquery_keys {params.dataset_cquery_keys} ; "

    rule irods_download_datasets:
        input:
            bilan = "config/datasets_query_bilan.tsv",
        output:
            path = directory(config["STORAGE_PATH"]),
        params:
            qkey = config["iRODS_BILAN_QUERY_KEY"],
        threads: 1
        resources:
            queue  = "shortq",
            mem_mb = 10240,
            disk_mb  = dataset_size * 1024,
            time_min = dataset_size,
        log:
            out = "logs/data/download/irods/irods_download_datasets.log"
        benchmark:
            "logs/benchmark/data/download/irods/irods_download_datasets.tsv"
        run:
            "module load python ; python3.9 workflow/rules/data/download/scripts/irods_metadata_download.py --bilan {input.bilan} --path {output.path} --qkey {params.qkey} ; "

