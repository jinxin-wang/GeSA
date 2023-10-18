example of [configuration file](https://github.com/jinxin-wang/Genome_Sequencing_Analysis/blob/andrei_modi_final/workflow/config/concat.yaml)


#### 1. concatenated by sample meta information table such as in the following example: 
```
$ cat sample_sheet.tsv
'sampleId\t'protocol'\t'R1'\'R2'
ST3227_T\tWES_seq\t/somewhere/iRODS_Download_20230927/ST3227_T/ST3227_T_S1_L004_R1_001.fastq.gz\t/somewhere/iRODS_Download_20230927/ST3227_T/ST3227_T_S1_L004_R2_001.fastq.gz
ST3227_R\trna\t/somewhere/iRODS_Download_20230927/ST3227_R/ST3259_R_EKRN230016864-1A_HTWYYDSX5_L1_1.fq.gz\t/somewhere/iRODS_Download_20230927/ST3227_R/ST3259_R_EKRN230016864-1A_HTWYYDSX5_L1_2.fq.gz
ST3227_R\trna\t/somewhere/iRODS_Download_20230927/ST3227_R/ST3259_R_EKRN230016864-1A_HWNVTDSX5_L1_1.fq.gz\t/somewhere/iRODS_Download_20230927/ST3227_R/ST3259_R_EKRN230016864-1A_HWNVTDSX5_L1_2.fq.gz
```

#### 2. concatenated by given directly the directory of samples
The directory of samples must be like the following layout: 
```
dir/
  |- sample1/
    |- subfolders/
         |- line1_read1.fq.gz
         |- line1_read2.fq.gz
         |- line2_read1.fq.gz
         |- line2_read2.fq.gz
    |- subfolders/
         |- line3_read1.fq.gz
         |- line3_read2.fq.gz
     ....
  |- sample2/
     ....
```

for example: 
```
/mnt/beegfs/scratch/j_wang/01_RawData/STING_UNLOCK/STING_UNLOCK_Batch3_META/iRODS_Download_20230927/
├── ST2194_N
│   ├── ST2194_N_S1_L003_R1_001.fastq.gz
│   └── ST2194_N_S1_L003_R2_001.fastq.gz
├── ST2194_R
│   ├── ST2194_R_EKRN230037912-1A_HJGVCDSX7_L3_1.fq.gz
│   └── ST2194_R_EKRN230037912-1A_HJGVCDSX7_L3_2.fq.gz
├── ST2194_T
│   ├── ST2194_T_S1_L003_R1_001.fastq.gz
│   └── ST2194_T_S1_L003_R2_001.fastq.gz
├── ST2405_N
│   ├── ST2405_N_S1_L003_R1_001.fastq.gz
│   └── ST2405_N_S1_L003_R2_001.fastq.gz
├── ST3227_R
│   ├── ST3227_R_EKRN230037909-1A_HJGVCDSX7_L3_1.fq.gz
│   ├── ST3227_R_EKRN230037909-1A_HJGVCDSX7_L3_2.fq.gz
│   ├── ST3227_R_EKRN230037909-1A_HJHHJDSX7_L2_1.fq.gz
│   └── ST3227_R_EKRN230037909-1A_HJHHJDSX7_L2_2.fq.gz
├── ST3227_T
│   ├── ST3227_T_S1_L004_R1_001.fastq.gz
│   └── ST3227_T_S1_L004_R2_001.fastq.gz

```
