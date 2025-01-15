import os
import sys
import glob
import logging
import subprocess
from pathlib import Path
from SigProfilerAssignment import Analyzer 
from SigProfilerMatrixGenerator.scripts import SigProfilerMatrixGeneratorFunc as matGen

is_wes     = sys.argv[1] == "WES"
input_path = Path(sys.argv[2]).absolute()
output_path= Path(sys.argv[3]).absolute()

logging.basicConfig(format='%(asctime)s,%(msecs)d %(name)s %(levelname)s %(message)s',
                    datefmt='%H:%M:%S',
                    level = logging.DEBUG)

os.makedirs(Path(output_path), exist_ok=True)

for vcf in glob.glob(f"{input_path}/*vcf.gz"):
    pass_vcf = Path(vcf).name.replace("vcf.gz", "PASS.vcf")
    result = subprocess.run([f"zgrep -e '#' -e 'PASS' {vcf} > {output_path.joinpath(pass_vcf)}"], shell=True, capture_output=True, text=True)
    if len(result.stdout):
        logger.info(result.stdout)
    if len(result.stderr):
        logger.error(result.stderr)
    
matrices = matGen.SigProfilerMatrixGeneratorFunc(f"Results", "GRCh37", f"{output_path}", plot=True, exome=is_wes, bed_file=None, chrom_based=False, tsb_stat=True, seqInfo=True, cushion=0)

SBS96 = f"Results.SBS96.exome" if is_wes else f"Results.SBS96.all" 
SBS_path = output_path.joinpath(f"output/SBS/{SBS96}")
SBS_out_path = output_path.joinpath("SBS_cosmic_fit")

logging.info(f"SBS input path: {SBS_path}")
logging.info(f"SBS output path: {SBS_out_path}")

try:
    Analyzer.cosmic_fit(samples=f"{SBS_path}", output=f"{SBS_out_path}", input_type="matrix", genome_build="GRCh37", cosmic_version=3.4)
except Exception as e:
    logging.exception(e)
    raise(e)

# ID96  = f"Results.ID96.exome" if is_wes else f"Results.ID96.all"
# ID_path = output_path.joinpath(f"output/ID/{ID96}")
# ID_out_path = output_path.joinpath("ID_cosmic_fit")

# logger.info(f"ID input path: {ID_path}")
# logger.info(f"ID output path: {ID_out_path}")

# try:
#     Analyzer.cosmic_fit(samples=f"{ID_path}",  output=f"{ID_out_path}",  input_type="matrix", genome_build="GRCh37", cosmic_version=3.4)
# except Exception as e:
#     logger.exception(e)

