import os
import sys
import glob
import logging
import subprocess
import pandas as pd
from   pathlib import Path

# The European Genome-phenome Archive (EGA) 
EGA   = "EGA"

# Integrated Rule-Oriented Data System (iRODS)
IRODS = "iRODS"

# Amazon Simple Storage Service
AMAZON= "S3"

# BGI Genomics, GeneAn
# https://genean-static-master.oss-cn-shenzhen.aliyuncs.com/ff-en.tar.gz
# https://genean-static-master.oss-cn-shenzhen.aliyuncs.com/ff-cn.tar.gz
BGI="GeneAn"

# FTP Server
FTP="ftp"

# backup storage on cluster, such as glustergv0, isilon
STORAGE="backup"

configfile: "workflow/config/download.yaml", 

dataset_size = int(config["DATASET_SIZE"].replace('G','').split('.')[0]) + 1 

if sys.version_info.major < 3:
    logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))
    
logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)


if   config["DATABASE"] == IRODS:
    include: "irods/download.smk"
elif config["DATABASE"] == AMAZON:
    include: "s3/download.smk"
elif config["DATABASE"] == EGA:
    include: "ega/download.smk"
elif config["DATABASE"] == BGI:
    include: "genean/download.smk"
elif config["DATABASE"] == FTP:
    include: "ftp/download.smk"
# elif config["DATABASE"] == STORAGE:
#     include: "cluster/download.smk"
    
rule download_targets:
    input:
        row_data = config["STORAGE_PATH"]
