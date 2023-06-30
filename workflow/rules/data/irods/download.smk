rule gen_irods_download_bash:
    input:
        meta = config["general"]["MetaTable"],
    output:
        script = config["general"]["DownloadScript"],
    log:
        "logs/download/gen_irods_download_bash.log"
    params:
        pj_name      = config["general"]["ProjectName"],
        storage_path = config["general"]["StoragePath"],
        gb_attrs     = config["irods"]["GroupByAttrs"]
        queue        = "shortq",
    threads: 1
    resources:
        mem_mb = 1024
    run:
        import pandas as pd
	
        df = pd.read_csv(str(input.meta), sep='\t', header=0)
	## group by two attributs, for example : patientId and protocol
        df = df.groupby(params.gb_attrs)
        
	with open(str(output.script), 'w') as fd: 
            for name, group in df:
                file_path = "%s/%s/%s"%(storage_path, name[0], name[1].replace(" ", "_").replace("-", "_"))
                fd.writeline("mkdir -p %s ; "%file_path)
                fd.writeline("cd %s ; "%file_path)
                for data_path in group['datafilePath']:
		    src_num = data_path.split('/')[3]
                    fd.writeline("iget -K %s %s ; "%(data_path, src_num))



rule exec_irods_download:
    input:
        meta="conf/download.sh"
    output:
        temp("conf/download_success")
    log:
        "logs/download/exec_irods_download.log"
    params:
        queue = "longq",
    threads: 8
    resources:
        mem_mb = 10240
    shell:
        "bash conf/download.sh 2> {log} "
	" && touch conf/download_success "
