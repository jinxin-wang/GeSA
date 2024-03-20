import os
import sys
import string
import logging
import argparse
import pandas as pd

sys.path.append(os.path.abspath("some private path of lib"))

# from libIRODS import * 

def main(input, output, params):
    pass

parser = argparse.ArgumentParser(description='inputs from the rule')
parser.add_argument('--opt1')
parser.add_argument('--opt2')
parser.add_argument('--opt3')
parser.add_argument('--opt4', type=int) 
parser.add_argument('--opt5')
parser.add_argument('--opt6')

input  = parser.parse_args()
output = parser.parse_args()
params = parser.parse_args()
log    = parser.parse_args()

if sys.version_info.major < 3:
    logging.warning(f"require python3, current python version: {sys.version_info[0]}.{sys.version_info[1]}.{sys.version_info[2]}")
        
# logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.DEBUG)
logging.basicConfig(filename=log.out, level=logging.DEBUG)

# values from input in the rule 
logging.info(f"input.opt1: {input.opt1}")
logging.info(f"input.opt2: {input.opt2}")

# values from output in the rule 
logging.info(f"output.opt3: {output.opt3}")

# values from params in the rule 
logging.info(f"params.opt4: {params.opt4}")
logging.info(f"params.opt5: {params.opt5}")

# values from log in the rule 
logging.info(f"log.out: {log.out}")

# start 
main(input, output, params)
