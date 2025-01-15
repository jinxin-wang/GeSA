# https://github.com/walaj/svaba
# latest 1.2.0

'''
git clone --recursive https://github.com/walaj/svaba
cd svaba
mkdir build
cd build

## replace the paths below with the paths on your own system
## >= GCC-4.8 
cmake .. -DHTSLIB_DIR=/home/jaw34/software/htslib-1.16
make

## QUICK START (eg run tumor / normal on Chr22, with 4 cores)
build/svaba -t tumor.bam -n normal.bam -k 22 -G ref.fa -a test_id -p -4

## get help
svaba --help
svaba run --help
'''

# conda install bioconda::svaba
# 1.1.0

'''
wget "https://data.broadinstitute.org/snowman/dbsnp_indel.vcf" ## get a DBSNP known indel file
DBSNP=dbsnp_indel.vcf
CORES=8 ## set any number of cores
REF=/seq/references/Homo_sapiens_assembly19/v1/Homo_sapiens_assembly19.fasta
## -a is any string you like, which gives the run a unique ID
svaba run -t $TUM_BAM -n $NORM_BAM -p $CORES -D $DBSNP -a somatic_run -G $REF
'''

rule somatic_svaba_TvN:
    input:
        tbam = "bam/{tsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam",
        nbam = "bam/{nsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{nsample}.recal.bam",
        tbai = "bam/{tsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam.bai",        
        nbai = "bam/{nsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{nsample}.recal.bam.bai",        
    output:
        path= "sv_svaba_TvN"
        maf = "sv_svaba_TvN/{tsample}_vs_{nsample}.svaba.maf",
    log:
        "logs/sv_svaba_TvN/{tsample}_vs_{nsample}.log" 
    conda:
        "svaba"
    params:
        queue = "shortq",
        svaba = config["svaba"]["script"],
        ref   = config[""]["ref"],
        dbsnp = config["svaba"]["dbsnp"],
    threads: 1
    resources:
        queue  = "shortq",
        mem_mb = 4096,
    shell:
        """
        {params.svaba} run \
            -n {input.nbam} \
            -t {input.tbam} \
            -G {params.ref} \
            -k 22 -p {threads} \
            -a somatic_run \
            -D {params.dbsnp} 2> {log}
        """

'''
## Set -I to not do mate-region lookup if mates are mapped to different chromosome.
##   This is appropriate for germline-analysis, where we don't have a built-in control
##   to against mapping artifacts, and we don't want to get bogged down with mate-pair
##   lookups.
## Set -L to 6 which means that 6 or more mate reads must be clustered to 
##   trigger a mate lookup. This also reduces spurious lookups as above, and is more 
##   appropriate the expected ALT counts found in a germline sample 
##   (as opposed to impure, subclonal events in cancer that may have few discordant reads).
svaba run -t $GERMLINE_BAM -p $CORES -L 6 -I -a germline_run -G $REF
'''

rule germline_svaba_T:
    input:
        tbam = "bam/{tsample}.nodup.recal.bam" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam",
        tbai = "bam/{tsample}.nodup.recal.bam.bai" if config["remove_duplicates"] == True else "bam/{tsample}.recal.bam.bai",        
    output:
        path= "sv_svaba_TvN"
        maf = "sv_svaba_TvN/{tsample}.svaba.maf",
    log:
        "logs/sv_svaba_TvN/{tsample}.log" 
    conda:
        "svaba"
    params:
        queue = "shortq",
        svaba = config["svaba"]["script"],
        ref   = config[""]["ref"],
        dbsnp = config["svaba"]["dbsnp"],
    threads: 1
    resources:
        queue  = "shortq",
        mem_mb = 4096,
    shell:
        """
        {params.svaba} run \
            -t {input.tbam} \
            -G {params.ref} \
            -k 22 -p {threads} \
            -L 6 -I \
            -a somatic_run \
            -D {params.dbsnp} 2> {log}
        """
