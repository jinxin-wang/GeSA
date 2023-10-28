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

DATASET_SIZE = config["DATASET_SIZE"] 

if type(DATASET_SIZE) == int  or type(DATASET_SIZE) == float :
    dataset_size = int(DATASET_SIZE)
elif type(DATASET_SIZE) == str and str(config["DATASET_SIZE"])[-1] == 'G' :
    dataset_size = int(config["DATASET_SIZE"].replace('G','').split('.')[0]) + 1 
elif type(DATASET_SIZE) == str and str(config["DATASET_SIZE"])[-1] == 'T' :
    dataset_size = ( int(config["DATASET_SIZE"].replace('T','').split('.')[0]) + 1 ) * 1024
elif type(DATASET_SIZE) == str and str(config["DATASET_SIZE"])[-1] == 'M' :
    dataset_size = int ( ( int(config["DATASET_SIZE"].replace('T','').split('.')[0]) + 1 ) / 1024 )
else:
    raise Exception("[Error] Unable to identify data size set in configuration file. ")
    
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
