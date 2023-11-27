rule match_civic_disease:
    input:
        patient_table = annotation_config["general"]["patients"],
    output:
        pairs_table   = annotation_config["general"]["tumor_normal_pairs"],
    log:
        out = "logs/conf/match_civic_disease.log",
    params:
        corr_table = annotation_config["params"]["civic"]["corr_table"],
    threads: 1
    resources:
        queue = "shortq",
        mem_mb= 4000,
    run:
        if sys.version_info.major < 3:
            logging.warning(f"require python3, current python version: {sys.version_info[0]}.{sys.version_info[1]}.{sys.version_info[2]}")
        
        logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.DEBUG)
        
        def match_gender(row):
            if str(row["Sex"]).strip()[0] == "F":
                return "Female"

            elif str(row["Sex"]).strip()[0] == "M":
                return "Male"

            return None
            
        def match_civic(row): 

            civic_set  = set()
            
            def civic_string_to_set(civic_str):
                civic_str = str(civic_str)
                return set(civic_str.split('|'))

            try : 
                if pd.notnull(row["Project_TCGA_More"]) and pd.notnull(row["MSKCC_Oncotree"]):
                    tcga = row["Project_TCGA_More"]
                    oncotree = row["MSKCC_Oncotree"]
                    logging.info(f"TCGA: {tcga} , OncoTree: {oncotree} ")
                    for civic in corresp.loc[tcga, oncotree]["Civic_Disease"]:
                        if pd.notnull(civic):
                            civic_set.update(civic_string_to_set(civic))
                            
                elif pd.notnull(row["Project_TCGA_More"]):
                    tcga = row["Project_TCGA_More"]
                    logging.info(f"TCGA: {tcga} ")
                    for civic in corresp.loc[tcga, :]["Civic_Disease"]:
                        if pd.notnull(civic):
                            civic_set.update(civic_string_to_set(civic))
                
                elif pd.notnull(row["MSKCC_Oncotree"]):
                    oncotree = row["MSKCC_Oncotree"]
                    logging.info(f"Oncotree: {oncotree} ")
                    for civic in corresp.loc[:, oncotree]["Civic_Disease"]:
                        if pd.notnull(civic):
                            civic_set.update(civic_string_to_set(civic))
                            
                # elif pd.isnull(row["Project_TCGA_More"]) and pd.isnull(row["MSKCC_Oncotree"]):
                # DO NOTHING
                #     pass

            except KeyError as err: 

                logging.debug(f"patient id: {patient_id}, error: KeyError [{err}]")
                
                if pd.notnull(row["Project_TCGA_More"]) :
                    tcga     = re.split('-|_| ', str(row["Project_TCGA_More"]))[0]
                    logging.debug(f"TCGA: {tcga} ")
                    
                if pd.notnull(row["MSKCC_Oncotree"]) :
                    oncotree = re.split('-|_| ', str(row["MSKCC_Oncotree"]))[0]
                    logging.debug(f"OncoTre: {oncotree} ")

                if pd.isnull(row["Project_TCGA_More"]) :
                    tcga     = oncotree
                    logging.debug(f"set oncotree to tcga: {oncotree} ")

                if pd.isnull(row["MSKCC_Oncotree"]) :
                    oncotree = tcga
                    logging.debug(f"set tcga to oncotree: {tcga} ")

                query_cmd = f"Project_TCGA_More.str.contains('{tcga}') and MSKCC_Oncotree.str.contains('{oncotree}') "
                logging.info(f"Query cmd: {query_cmd} ")
                for civic in corresp.query(query_cmd, engine='python')["Civic_Disease"]:
                    if pd.notnull(civic):
                        civic_set.update(civic_string_to_set(civic))

                if len(civic_set) == 0:
                    query_cmd = f"Project_TCGA_More == '{tcga}' or MSKCC_Oncotree == '{oncotree}' "
                    logging.info(f"Query cmd: {query_cmd} ")
                    for civic in corresp.query(query_cmd, engine='python')["Civic_Disease"]:
                        if pd.notnull(civic):
                            civic_set.update(civic_string_to_set(civic))
                        
            return "|".join(civic_set)
        
        # corresp = pd.read_excel(params.corr_table, header = 0)
        corresp = pd.read_csv(params.corr_table, sep='\t', header=0).set_index(['Project_TCGA_More', 'MSKCC_Oncotree'])
        
        # the column names for the patient_table is : 
        # PATIENT_ID, Project_TCGA_More, MSKCC_Oncotree, Sex
        patient = pd.read_csv(input.patient_table, sep='\t', header = 0)
        patient = patient.reset_index()
        
        # the column names for the pairs_table is : 
        # Subject_Id, Sample_Id, DNA_T, DNA_N, DNA_P, Project_TCGA_More, MSKCC_Oncotree, Civic_Disease, Gender
        pairs   = []
        
        subject_ids = abs(patient["PATIENT_ID"].map(hash))

        for index, row in patient.iterrows():

            # subject_id = str(subject_ids[index])
            patient_id = str(row["PATIENT_ID"])
            subject_id = patient_id
            dna_t      = "%s_T"%patient_id
            dna_n      = "%s_N"%patient_id
            dna_p      = "%s_T_vs_%s_N"%(patient_id,patient_id)
            civic_codes= match_civic(row)
            tcga       = str(row["Project_TCGA_More"])
            oncokb     = str(row["MSKCC_Oncotree"])
            gender     = match_gender(row)

            pairs.append([subject_id, patient_id, dna_t, dna_n, dna_p, tcga, oncokb, civic_codes, gender])
        
        pd.DataFrame(pairs).to_csv(output.pairs_table, sep='\t', index=False,
                header = ["Subject_Id", "Sample_Id", "DNA_T", "DNA_N", "DNA_P", "Project_TCGA_More", "MSKCC_Oncotree", "Civic_Disease", "Gender"])


rule extract_samples_table:
    input:
        pairs_table  = annotation_config["general"]["tumor_normal_pairs"]
    output:
        sample_table = annotation_config["general"]["samples"]
    log:
        out = "logs/conf/extract_samples_table.log"
    threads: 1
    resources:
        queue = "shortq",
        mem_mb= 4000,
    run:
        if sys.version_info.major < 3:                                                                                                                                                                                                            
            logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

        logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)
        
        samples  = []

        pairs_df = pd.read_csv(input.pairs_table, sep='\t').reset_index()
        
        for index, row in pairs_df.iterrows():
            samples.append([row["Subject_Id"], row["DNA_N"], "DNA_N", "OK", row["Project_TCGA_More"], row["MSKCC_Oncotree"], row["Civic_Disease"], row["Gender"]])
            samples.append([row["Subject_Id"], row["DNA_T"], "DNA_T", "OK", row["Project_TCGA_More"], row["MSKCC_Oncotree"], row["Civic_Disease"], row["Gender"]])
    
        pd.DataFrame(samples).to_csv(output.sample_table, sep='\t', index=False,
            header = ["Subject_Id", "Sample_Id","Sample_Type","IRODS_Status","Project_TCGA_More","MSKCC_Oncotree","Civic_Disease","Gender"]) 
