rule gen_irods_download_bash:
    input:
        meta="sample.csv"
    output:
        "conf/download.sh"
    log:
        "logs/download/gen_irods_download_bash.log"
    params:
        queue = "shortq",
    	conf  = "conf/?.json/?.yaml"
        threads: 1
        resources:
        mem_mb = 1024
    run:
        storage_path = "/mnt/beegfs/scratch/$USER/projectname"
        df = pd.read_csv(meta, sep=';')
        df = df.groupby(['patientId', 'protocol'])
        
        for name, group in df:
            file_path = "%s/%s/%s"%(storage_path, name[0], name[1].replace(" ", "_").replace("-", "_"))
            print("")
            print("mkdir -p %s ; "%file_path)
            print("cd %s ; "%file_path)
            for data_path in group['datafilePath']:
                print("iget -K %s ; "%data_path)



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
