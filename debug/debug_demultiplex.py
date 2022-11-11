#!/usr/bin/env python3
"""
Purpose: Helper script to demultiplex phased primers using a subprocess wrapper.
"""
__author__ = "Erick Samera"
__version__ = "1.2.0"
__comment__ = 'stable'

# --------------------------------------------------
from argparse import (
    Namespace,
    ArgumentParser,
    ArgumentDefaultsHelpFormatter)
from pathlib import Path
import time
# --------------------------------------------------
import pandas as pd
from Bio import SeqIO
# --------------------------------------------------
def get_args() -> Namespace:
    """ Get command-line arguments """

    parser = ArgumentParser(
        #usage='%(prog)s',
        description="Helper script to demultiplex phased primers using a subprocess wrapper.",
        epilog=f"v{__version__} : {__author__} | {__comment__}",
        formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        'input_path',
        type=Path,
        help="path of directory containing .fastq files from custom demultiplexer")
    parser.add_argument(
        '-i',
        '--i-clc',
        dest='clc_input_path',
        metavar='PATH',
        type=Path,
        required=True,
        help="REQUIRED: path of directory containing CLC-demultiplexed .fastq")
    # --------------------------------------------------

    args = parser.parse_args()

    # parser errors and processing
    # --------------------------------------------------

    return args
# --------------------------------------------------
def compare_fastq(orig_fastq_arg: Path, clc_fastq_arg: Path) -> list:
    """
    """
    orig_fastq_list: list = [seq.id for seq in SeqIO.parse(orig_fastq_arg, 'fastq')]
    clc_fastq_list: list = [seq.id for seq in SeqIO.parse(clc_fastq_arg, 'fastq')]

    not_in_orig = [fastq for fastq in clc_fastq_list if not fastq in orig_fastq_list]
    not_in_clc = [fastq for fastq in orig_fastq_list if not fastq in clc_fastq_list]


    # print(f'There were {len(orig_fastq_list)} entries in the original fastq list.')
    # print(f'There were {len(clc_fastq_list)} entries in the CLC genomics fastq list.')

    # print(f'There are {len(not_in_orig) + len(not_in_clc)} different reads between them.')
    # print(f'There are {len(not_in_orig)} reads not found in the original fastq list. ({100 - (len(not_in_orig)/len(orig_fastq_list)*100)} % were present)')
    # print(f'There are {len(not_in_clc)} reads not found in the CLC fastq list. ({100 - (len(not_in_clc)/len(clc_fastq_list)*100)} % were present)')

    # print(f'They are {100 - ((len(not_in_orig) + len(not_in_clc)) / (len(orig_fastq_list)+len(clc_fastq_list))*100)} % the same.')

    return 1 - ((len(not_in_orig) + len(not_in_clc)) / (len(orig_fastq_list)+len(clc_fastq_list)))
# --------------------------------------------------
def main() -> None:
    """ Insert docstring here """

    args = get_args()
    reads = ['R1', 'R2']

    r1_r2: dict = {}
    read_similar_dict: dict = {}

    for read_num in reads:
        for file in args.input_path.glob(f'*{read_num}*'):
            try:
                sample_name = file.name.split('_')[0]
                region = file.name.split('_')[3]
                fastq_orig = file
                fastq_clc = ([file for file in args.clc_input_path.glob(f'{sample_name}*{region}*{read_num}*')][0])
                print(f'{sample_name}_{region}_{read_num}')
                r1_r2_sample_name = f'{sample_name}_{region}'

                if not sample_name in read_similar_dict:
                    read_similar_dict[sample_name] = {}
                if not r1_r2_sample_name in r1_r2:
                    r1_r2[r1_r2_sample_name] = {}
                comparison_result = compare_fastq(fastq_orig, fastq_clc)
                r1_r2[r1_r2_sample_name][read_num] = comparison_result
                read_similar_dict[sample_name][f'{read_num}_{region}'] = comparison_result
            except: pass

    pd.DataFrame.from_dict(read_similar_dict, orient='index').to_csv('results_by-region.csv')
    pd.DataFrame.from_dict(r1_r2, orient='index').to_csv('results_r1-r2.csv')
    return None
def print_runtime(action) -> None:
    """ Return the time and some defined action. """
    print(f'[{time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())}] {action}')
# --------------------------------------------------
if __name__ == '__main__':
    main()
