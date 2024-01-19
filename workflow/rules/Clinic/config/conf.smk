def match_gender(row):
    if str(row["Sex"]).strip()[0] == "F":
        return "Female"

    elif str(row["Sex"]).strip()[0] == "M":
        return "Male"
    
    return None
            
def match_civic(row, corresp): 

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
        patient_id = str(row["PATIENT_ID"])
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

rule extract_aggregate_sample_table:
    input:
        patient_table = annotation_config["general"]["patients"],
    output:
        sample_table  = annotation_config["general"]["agg_sample"],
    log:
        out = "logs/conf/extract_aggregate_sample_table.log",
    params:
        all_sample_dir= annotation_config["all_sample_dir"],
        corr_table = annotation_config["params"]["civic"]["corr_table"],
    threads: 1
    resources:
        queue = "shortq",
        mem_mb= 4000,
    run:
        if sys.version_info.major < 3:
            logging.warning(f"require python3, current python version: {sys.version_info[0]}.{sys.version_info[1]}.{sys.version_info[2]}")
        
        logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.DEBUG)
        
        # corresp = pd.read_excel(params.corr_table, header = 0)
        corresp = pd.read_csv(params.corr_table, sep='\t', header=0).set_index(['Project_TCGA_More', 'MSKCC_Oncotree'])
        
        # the column names for the patient_table is : 
        # PATIENT_ID, Project_TCGA_More, MSKCC_Oncotree, Sex
        patient = pd.read_csv(input.patient_table, sep='\t', header = 0)
        patient = patient.reset_index()
        
        # sample_dir = params.all_sample_dir
        
        # if not os.path.isdir(sample_dir) :
        #     logging.error(f"the directory does NOT exist : {sample_dir} ")
        #     exit(-1)

        # the column names for table is : 
        # Subject_Id, Sample_Type, Sample_Id_DNA_N, Sample_Id_DNA_T, Sample_Id_RNA_T, Project_TCGA_More, MSKCC_Oncotree, Civic_Disease, Gender
        
        # subject_ids = abs(patient["PATIENT_ID"].map(hash))

        sample_table = []

        for index, row in patient.iterrows():

            # subject_id = str(subject_ids[index])
            patient_id = str(row["PATIENT_ID"])
            subject_id = patient_id
            sid_dna_t  = "%s_T"%patient_id # if os.path.isfile(f"{sample_dir}/{patient_id}_T_R1.fastq.gz") and os.path.isfile(f"{sample_dir}/{patient_id}_T_R2.fastq.gz") else ""
            sid_dna_n  = "%s_N"%patient_id # if os.path.isfile(f"{sample_dir}/{patient_id}_N_R1.fastq.gz") and os.path.isfile(f"{sample_dir}/{patient_id}_N_R2.fastq.gz") else ""
            sid_rna_t  = "%s_R"%patient_id # if os.path.isfile(f"{sample_dir}/{patient_id}_R_R1.fastq.gz") and os.path.isfile(f"{sample_dir}/{patient_id}_R_R2.fastq.gz") else ""
            sample_type= set([sid_dna_n, sid_dna_t, sid_rna_t])

            if "" in sample_type :
                sample_type.remove("")

            sample_type= "|".join(list(sample_type))
            civic_codes= match_civic(row, corresp)
            tcga       = str(row["Project_TCGA_More"])
            oncokb     = str(row["MSKCC_Oncotree"])
            gender     = match_gender(row)

            sample_table.append([subject_id, sample_type, sid_dna_n, sid_dna_t, sid_rna_t, tcga, oncokb, civic_codes, gender])
        
        pd.DataFrame(sample_table).to_csv(output.sample_table, sep='\t', index=False,
               header = ["Subject_Id", "Sample_Type", "Sample_Id_DNA_N", "Sample_Id_DNA_T", "Sample_Id_RNA_T", "Project_TCGA_More", "MSKCC_Oncotree", "Civic_Disease", "Gender"])
        
        # header = ["Subject_Id", "Sample_Id", "DNA_T", "DNA_N", "DNA_P", "Project_TCGA_More", "MSKCC_Oncotree", "Civic_Disease", "Gender"])

rule extract_tumor_normal_pairs:
    input:
        patient_table = annotation_config["general"]["patients"],
    output:
        pairs_table   = annotation_config["general"]["tumor_normal_pairs"],
    log:
        out = "logs/conf/extract_tumor_normal_pairs.log",
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
        
        # corresp = pd.read_excel(params.corr_table, header = 0)
        corresp = pd.read_csv(params.corr_table, sep='\t', header=0).set_index(['Project_TCGA_More', 'MSKCC_Oncotree'])
        
        # the column names for the patient_table is : 
        # PATIENT_ID, Project_TCGA_More, MSKCC_Oncotree, Sex
        patient = pd.read_csv(input.patient_table, sep='\t', header = 0)
        patient = patient.reset_index()
        
        # the column names for the table is : 
        # Subject_Id, Sample_Id, DNA_T, DNA_N, DNA_P, Project_TCGA_More, MSKCC_Oncotree, Civic_Disease, Gender
        lines   = []

        logging.info(patient.columns)
        
        # subject_ids = abs(patient["PATIENT_ID"].map(hash))

        for index, row in patient.iterrows():

            # subject_id = str(subject_ids[index])
            patient_id = str(row["PATIENT_ID"])
            subject_id = patient_id
            dna_t      = "%s_T"%patient_id
            dna_n      = "%s_N"%patient_id
            dna_p      = "%s_T_vs_%s_N"%(patient_id,patient_id)
            civic_codes= match_civic(row, corresp)
            tcga       = str(row["Project_TCGA_More"])
            oncokb     = str(row["MSKCC_Oncotree"])
            gender     = match_gender(row)

            lines.append([subject_id, patient_id, dna_t, dna_n, dna_p, tcga, oncokb, civic_codes, gender])
        
        pd.DataFrame(lines).to_csv(output.pairs_table, sep='\t', index=False,
                header = ["Subject_Id", "Sample_Id", "DNA_T", "DNA_N", "DNA_P", "Project_TCGA_More", "MSKCC_Oncotree", "Civic_Disease", "Gender"])


rule extract_dna_samples_table:
    input:
        patient_table = annotation_config["general"]["patients"],
    output:
        sample_table = annotation_config["general"]["dna_samples"]
    log:
        out = "logs/conf/extract_dna_samples_table.log",
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
        
        # corresp = pd.read_excel(params.corr_table, header = 0)
        corresp = pd.read_csv(params.corr_table, sep='\t', header=0).set_index(['Project_TCGA_More', 'MSKCC_Oncotree'])
        
        # the column names for the patient_table is : 
        # PATIENT_ID, Project_TCGA_More, MSKCC_Oncotree, Sex
        patient = pd.read_csv(input.patient_table, sep='\t', header = 0)
        patient = patient.reset_index()
        
        # the column names for the table is :
        # "Subject_Id", "Sample_Id","Sample_Type","IRODS_Status","Project_TCGA_More","MSKCC_Oncotree","Civic_Disease","Gender"
        lines   = []

        logging.info(patient.columns)
        
        # subject_ids = abs(patient["PATIENT_ID"].map(hash))

        for index, row in patient.iterrows():

            # subject_id = str(subject_ids[index])
            patient_id = str(row["PATIENT_ID"])
            subject_id = patient_id
            civic_codes= match_civic(row, corresp)
            tcga       = str(row["Project_TCGA_More"])
            oncotree   = str(row["MSKCC_Oncotree"])
            gender     = match_gender(row)

            lines.append([subject_id, f"{patient_id}_N", "DNA_N", "OK", tcga, oncotree, civic_codes, gender])
            lines.append([subject_id, f"{patient_id}_T", "DNA_T", "OK", tcga, oncotree, civic_codes, gender])
        
        pd.DataFrame(lines).to_csv(output.pairs_table, sep='\t', index=False,
                header = ["Subject_Id", "Sample_Id","Sample_Type","IRODS_Status","Project_TCGA_More","MSKCC_Oncotree","Civic_Disease","Gender"]) 


# rule extract_dna_samples_table:
#     input:
#         pairs_table  = annotation_config["general"]["tumor_normal_pairs"]
#     output:
#         sample_table = annotation_config["general"]["dna_samples"]
#     log:
#         out = "logs/conf/extract_samples_table.log"
#     threads: 1
#     resources:
#         queue = "shortq",
#         mem_mb= 4000,
#     run:
#         if sys.version_info.major < 3:                                                                                                                                                                                                            
#             logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

#         logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)
        
#         samples  = []

#         pairs_df = pd.read_csv(input.pairs_table, sep='\t').reset_index()
        
#         for index, row in pairs_df.iterrows():
#             samples.append([row["Subject_Id"], row["DNA_N"], "DNA_N", "OK", row["Project_TCGA_More"], row["MSKCC_Oncotree"], row["Civic_Disease"], row["Gender"]])
#             samples.append([row["Subject_Id"], row["DNA_T"], "DNA_T", "OK", row["Project_TCGA_More"], row["MSKCC_Oncotree"], row["Civic_Disease"], row["Gender"]])
    
#         pd.DataFrame(samples).to_csv(output.sample_table, sep='\t', index=False,
#             header = ["Subject_Id", "Sample_Id","Sample_Type","IRODS_Status","Project_TCGA_More","MSKCC_Oncotree","Civic_Disease","Gender"]) 

rule build_rna_samples_table:
    input:
        patient_table = annotation_config["general"]["patients"],
    output:
        sample_table = annotation_config["general"]["rna_samples"],
    log:
        out = "logs/conf/build_rna_samples_table.log",
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
        
        # corresp = pd.read_excel(params.corr_table, header = 0)
        corresp = pd.read_csv(params.corr_table, sep='\t', header=0).set_index(['Project_TCGA_More', 'MSKCC_Oncotree'])
        
        # the column names for the patient_table is : 
        # PATIENT_ID, Project_TCGA_More, MSKCC_Oncotree, Sex
        patient = pd.read_csv(input.patient_table, sep='\t', header = 0)
        patient = patient.reset_index()
        
        # the column names for the table is : 
        # Subject_Id, Sample_Id, Sample_Id_Long, Sample_Id_RNA_T, FASTQ_1_Name, FASTQ_2_Name, IRODS_Status, Project_TCGA_More, MSKCC_Oncotree, Civic_Disease, Gender
        lines   = []

        logging.info(patient.columns)
        
        # subject_ids = abs(patient["PATIENT_ID"].map(hash))

        for index, row in patient.iterrows():

            # subject_id = str(subject_ids[index])
            patient_id = str(row["PATIENT_ID"])
            subject_id = patient_id
            sample_id  = f"{patient_id}_R"
            fq1        = f"results/data/fastq/{patient_id}_1.fastq.gz"
            fq2        = f"results/data/fastq/{patient_id}_2.fastq.gz"
            civic_codes= match_civic(row, corresp)
            tcga       = str(row["Project_TCGA_More"])
            oncokb     = str(row["MSKCC_Oncotree"])
            gender     = match_gender(row)

            lines.append([subject_id, sample_id, sample_id, sample_id, fq1, fq2, "OK", tcga, oncokb, civic_codes, gender])
        
        pd.DataFrame(lines).to_csv(output.pairs_table, sep='\t', index=False,
                header = ["Subject_Id", "Sample_Id", "Sample_Id_Long", "Sample_Id_RNA_T", "FASTQ_1_Name", "FASTQ_2_Name", "IRODS_Status", "Project_TCGA_More", "MSKCC_Oncotree", "Civic_Disease", "Gender"])

