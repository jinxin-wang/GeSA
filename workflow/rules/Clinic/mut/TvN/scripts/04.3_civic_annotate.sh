#!/bin/bash

set -e

while getopts ":a:b:c:d:e:f:m:n:o:t:l:" opt; do
    case $opt in
        a) table_alt+=("$OPTARG")
	    ;;
        b) table_cln="$OPTARG"
            ;;
        c) table_gen="$OPTARG"
            ;;
        d) table_pre="$OPTARG"
            ;;
        e) table_run="$OPTARG"
            ;;
        f) table_pos="$OPTARG"
            ;;
        m) code_dir="$OPTARG"
            ;;
        n) civic="$OPTARG"
            ;;
        o) rules="$OPTARG"
            ;;
        t) category="$OPTARG"
            ;;
        l) log="$OPTARG"
            ;;
        \?) echo "Invalid option -$OPTARG" >&2
            exit 1
            ;;
    esac

    case $OPTARG in
	-*) echo "Option $opt needs a valid argument"
	    exit 1
	    ;;
    esac
done

exec 3>&1 4>&2 >>${log} 2>&1

# convert array to space-separated values
table_alt=$(printf "%s" "${table_alt[*]}")

# preprocess table of alterations before annotating with CIViC
printf -- "-INFO: preparing table before annotating with CIViC...\n"

printf -- "python -u workflow/rules/Clinic/mut/TvN/scripts/04.1_civic_preprocess.py \
    --table_alt ${table_alt} \
    --table_cln ${table_cln} \
    --table_gen ${table_gen} \
    --gen_gene_name name \
    --category ${category} \
    --output ${table_pre} \n"

python -u workflow/rules/Clinic/mut/TvN/scripts/04.1_civic_preprocess.py \
    --table_alt ${table_alt} \
    --table_cln ${table_cln} \
    --table_gen ${table_gen} \
    --gen_gene_name name \
    --category ${category} \
    --output ${table_pre} 

printf -- "-INFO: running CIViC annotator...\n" 

printf -- "python -u ${code_dir}/civic.py \
    --input ${table_pre} \
    --civic ${civic} \
    --rules ${rules} \
    --category ${category} \
    --output ${table_run} \n "

# python -u ${code_dir}/civic.py \
python -u workflow/scripts/CivicAnnotator/civic.py \
    --input ${table_pre} \
    --civic ${civic} \
    --rules ${rules} \
    --category ${category} \
    --output ${table_run} 

printf -- "-INFO: postprocess CIViC annotations...\n" 

printf -- "python -u workflow/rules/Clinic/mut/TvN/scripts/04.2_civic_postprocess.py \
    --input ${table_run} \
    --output ${table_pos} \n"

python -u workflow/rules/Clinic/mut/TvN/scripts/04.2_civic_postprocess.py \
    --input ${table_run} \
    --output ${table_pos} 

#### || ( echo "Hugo_Symbol	Entrez_Gene_Id	NCBI_Build	Chromosome	Start_Position	End_Position	Strand	Variant_Classification	Variant_Type	Reference_Allele	Tumor_Seq_Allele1	Tumor_Seq_Allele2	dbSNP_RS	Tumor_Sample_Barcode	Matched_Norm_Sample_Barcode	Match_Norm_Seq_Allele1	Match_Norm_Seq_Allele2	HGVSc	HGVSp	HGVSp_Short	Transcript_ID	Exon_Number	t_depth	t_ref_count	t_alt_count	n_depth	n_ref_count	n_alt_count	all_effects	Allele	Gene	Feature	Feature_type	Consequence	cDNA_position	CDS_position	Protein_position	Amino_acids	Codons	Existing_variation	STRAND_VEP	SYMBOL	SYMBOL_SOURCE	HGNC_ID	BIOTYPE	CANONICAL	SIFT	PolyPhen	EXON	INTRON	SOMATIC	IMPACT	PHENO	FILTER	flanking_bps	gnomAD_AF	gnomAD_NFE_AF	gnomAD_AFR_AF	gnomAD_AMR_AF	CADD_PHRED	CADD_RAW	CADD_raw_hg19	DEOGEN2_score	DISTANCE	FATHMM_score	FLAGS	GERP++_RS	MAX_AF	MAX_AF_POPS	MutationAssessor_pred	MutationAssessor_score	MutationTaster_pred	MutationTaster_score	PROVEAN_score	Polyphen2_HVAR_pred	Polyphen2_HVAR_score	REVEL_score	SIFT_pred	SIFT_score	VEST4_score	fathmm-MKL_coding_score	gnomAD_ASJ_AF	gnomAD_EAS_AF	gnomAD_FIN_AF	gnomAD_OTH_AF	gnomAD_SAS_AF" > ${table_pos} && touch ${table_run} && touch ${table_pre} ) 
