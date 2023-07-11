rule gen_irods_download_bash:
    input:
        meta = config["general"]["MetaTable"],
    output:
        script = config["general"]["DownloadScript"],
    log:
        "logs/download/gen_irods_download_bash.log"
    params:
        storage_path = config["general"]["StoragePath"],
        gb_attrs     = config["irods"]["GroupByAttrs"],
        download_threads = config["irods"]["DownloadThreads"],
        queue        = "shortq",
    threads: 1
    resources:
        mem_mb = 1024
    run:
        import pandas as pd
        from pathlib import Path

        ## replace " ", "-" by "_"
        def sf(s):
            return s.replace(' ', '_').replace('-', '_')

        def write_cmd(data_path: str, patientId: str, protocol: str):
            file_name = data_path.split('dataset/')[-1]
            file_path = Path(params.storage_path).joinpath(patientId).joinpath(protocol).joinpath(file_name)
            fd.write("\nmkdir -p %s \n"%(file_path.parent))
            fd.write("cd %s ; \n"%(file_path.parent))
            fd.write("iget -fK -N %d %s ; \n"%(params.download_threads, data_path))
        
        meta_df = pd.read_csv(str(input.meta), sep='\t', header=0)
        
	with open(str(output.script), 'w') as fd :
            fd.write("set -e \n")
            for ind, row in meta_df.iterrows():
                patientId = sf(row[params.gb_attrs[0]].split('|')[0])
                protocol  = sf(row[params.gb_attrs[1]])
                write_cmd(row['R1'], patientId, protocol)
                write_cmd(row['R2'], patientId, protocol)

rule exec_irods_download:
    input:
        meta = config["general"]["DownloadScript"],
    output:
        config["irods"]["DownloadSucess"],
    log:
        "logs/download/exec_irods_download.log"
    params:
        queue = "longq",
    threads: config["irods"]["DownloadThreads"],
    resources:
        mem_mb = 10240
    shell:
        " bash {input.meta} 2> {log} && "
	" touch {output} "
