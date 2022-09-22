#!/usr/bin/env python3
"""
Purpose: Helper script to demultiplex phased primers using a subprocess wrapper.
"""
__author__ = "Erick Samera"
__version__ = "1.1.0"

# TODO: implement support for custom primers

# --------------------------------------------------
from argparse import (
    Namespace,
    ArgumentParser,
    ArgumentDefaultsHelpFormatter)
from pathlib import Path
# --------------------------------------------------
import subprocess
import os
import time
# --------------------------------------------------
def get_args() -> Namespace:
    """ Get command-line arguments """

    parser = ArgumentParser(
        #usage='%(prog)s',
        description="Helper script to demultiplex phased primers using a subprocess wrapper.",
        epilog=f"v{__version__} : {__author__} | First stable iteration.",
        formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        'input_path',
        type=Path,
        help="path of directory containing fastq/fastq.gz")
    parser.add_argument(
        '-o',
        '--out',
        dest='output_path',
        metavar='PATH',
        type=Path,
        help="path of directory to output demultiplexed fastq/fastq.gz")
    parser.add_argument(
        '-c',
        '--cat',
        dest='concatenate_path',
        metavar='PATH',
        type=Path,
        help="path of directory to output concatenated fastq/fastq.gz")
    # --------------------------------------------------
    group_custom_regions = parser.add_argument_group(
        title='custom region options')
    mut_ex_custom = group_custom_regions.add_mutually_exclusive_group()
    mut_ex_custom.add_argument(
        '-r',
        '--regions',
        dest='specific_regions',
        metavar='V-REGIONS',
        type=str,
        help='save computation time: enter in specific QIAseq regions like this "V1V2;V2V4" to only use specific primers')
    mut_ex_custom.add_argument(
        '-p',
        '--pools',
        dest='specific_pools',
        metavar='POOLS',
        type=str,
        help='save computation time: enter in specific QIAseq pools like this "1;2" to only use specific primer pools')

    args = parser.parse_args()

    # parser errors and processing
    # --------------------------------------------------
    if not args.input_path.resolve().exists():
        parser.error("Input directory doesn't exist.")
    if args.specific_regions:
        args.specific_regions = [region.strip() for region in args.specific_regions.upper().split(';') if region in ("V1V2","V2V3","V3V4","V4V5","V5V7","V7V9","ITS1")]
        if not args.specific_regions:
            parser.error("Couldn't process variable region input.")
    if args.specific_pools:
        args.specific_pools = [pool.strip() for pool in args.specific_pools.upper().split(';') if pool in ("1","2",)]
        if not args.specific_pools:
            parser.error("Couldn't process primer pool input.")

    return args
# --------------------------------------------------
def perform_trim(file_arg: Path, output_path_arg:Path, demux_primers_dict_arg: dict) -> None:
    start = time.time()
    print_runtime(f'Demultiplexing {file_arg.name} with {[primer for primer in demux_primers_dict_arg]} ...')
    for index, primer_info in enumerate(demux_primers_dict_arg.items()):
        primer_name, primer_seqs = primer_info

        file_variables: dict = {'r1_path': file_arg}
        file_variables['r1_intermediate_file'] = output_path_arg.joinpath(f'{Path(file_variables["r1_path"].stem).stem}_intermediate_{index}.fastq.gz')
        file_variables['r1_prev_intermediate_file'] = Path(str(file_variables['r1_intermediate_file']).replace(f"_intermediate_{index}", f"_intermediate_{index-1}"))
        if file_variables['r1_prev_intermediate_file'].exists():
            file_variables['r1_path'] = file_variables['r1_prev_intermediate_file']
        r1_output_raw = str(f'{Path(file_variables["r1_path"].stem).stem}').split('_')
        r1_output_raw.insert(3, primer_name)
        r1_output_processed = f"{'_'.join(r1_output_raw)}.fastq.gz".replace(f"_intermediate_{index-1}", "")
        file_variables['r1_output'] = output_path_arg.joinpath(r1_output_processed)

        if len(demux_primers_dict_arg) == 1:
            r1_output_raw = str(f'{Path(file_variables["r1_path"].stem).stem}').split('_')
            r1_output_raw.insert(3, 'ungrouped')
            r1_output_processed = f"{'_'.join(r1_output_raw)}.fastq.gz".replace(f"_intermediate_{index-1}", "")
            file_variables['r1_intermediate_file'] = output_path_arg.joinpath(r1_output_processed)

        r2_file_variables: dict = {}
        for r1_file_variable in file_variables:
            r2_file_variables[r1_file_variable.replace('r1', 'r2')] = Path(str(file_variables[r1_file_variable]).replace('R1', 'R2'))
        file_variables.update(r2_file_variables)

        parallel_str = f"\
            cutadapt \
            --minimum-length 1 \
            --pair-adapters \
            --pair-filter any \
            --match-read-wildcards \
            -g {primer_seqs['forward']} \
            -G {primer_seqs['reverse']} \
            -o {file_variables['r1_output']} \
            -p {file_variables['r2_output']} \
            --untrimmed-output {file_variables['r1_intermediate_file']} \
            --untrimmed-paired-output {file_variables['r2_intermediate_file']}" + '\
            {1} {2}'

        with subprocess.Popen([
                'parallel',
                '--link',
                '-j', '4',
                f'{parallel_str}',
                ':::', f"{file_variables['r1_path']}", ':::', f"{file_variables['r2_path']}"], stdout=subprocess.PIPE) as output:
            pass

    for index, output_file in enumerate(output_path_arg.glob(f'{str(Path(file_arg.stem).stem)}_intermediate_*.fastq.gz')):
            r1_intermediate_file = output_file
            r2_intermediate_file = Path(str(output_file).replace('R1', 'R2'))
            if index < len(demux_primers_dict_arg):
                os.remove(r1_intermediate_file)
                os.remove(r2_intermediate_file)
            else:
                old_name_replaced = str(Path(r1_intermediate_file.stem).stem).replace(f"_intermediate_{index}", "")
                old_name_raw = old_name_replaced.split('_')
                old_name_raw.insert(3, 'ungrouped')
                r1_new_name = f"{'_'.join(old_name_raw)}.fastq.gz"
                r2_new_name = r1_new_name.replace('R1', 'R2')
                os.rename(r1_intermediate_file, r1_intermediate_file.parent.joinpath(r1_new_name))
                os.rename(r2_intermediate_file, r1_intermediate_file.parent.joinpath(r2_new_name))
    end = time.time()
    print_runtime(f'Demultiplexed {file_arg.name} with {[primer for primer in demux_primers_dict_arg]} in {round(end - start, 3)} s.')

def condense_files(file_arg: Path, intermediate_output_path_parg: Path, output_path_arg: Path):
    file_prefix = file_arg.stem.split('_')[0]

    for read in ('R1', 'R2'):
        files_to_combine = [str(file) for file in intermediate_output_path_parg.glob(f'{file_prefix}*{read}*') if 'ungrouped' not in file.name]
        concat_arg = ['cat'] + files_to_combine + ['>'] + [str(output_path_arg.joinpath(str(file_arg.name).replace('R1', read)))]
        subprocess.call(' '.join(concat_arg), shell=True)

    print_runtime(f'Concatenated {file_arg.name} .')


# --------------------------------------------------
def main() -> None:
    """ Insert docstring here """

    args = get_args()

    # deal with output directory
    if not args.output_path.exists():
        Path(args.output_path).mkdir(parents=False, exist_ok=True)
    # deal with output directory
    if args.concatenate_path:
        if not args.concatenate_path.exists():
            Path(args.concatenate_path).mkdir(parents=False, exist_ok=True)

    # constants
    qiaseq_primers: dict = {
        "V1V2": {'forward': "AGRGTTTGATYMTGGCTC",'reverse': "CTGCTGCCTYCCGTA"},
        "V2V3": {'forward': "GGCGNACGGGTGAGTAA",'reverse': "WTTACCGCGGCTGCTGG"},
        "V3V4": {'forward': "CCTACGGGNGGCWGCAG",'reverse': "GACTACHVGGGTATCTAATCC"},
        "V4V5": {'forward': "GTGYCAGCMGCCGCGGTAA",'reverse': "CCGYCAATTYMTTTRAGTTT"},
        "V5V7": {'forward': "GGATTAGATACCCBRGTAGTC",'reverse': "ACGTCRTCCCCDCCTTCCTC"},
        "V7V9": {'forward': "YAACGAGCGMRACCC",'reverse': "TACGGYTACCTTGTTAYGACTT"},
        "ITS1": {'forward': "CTTGGTCATTTAGAGGAAGTAA",'reverse': "GCTGCGTTCTTCATCGATGC"},
        }
    qiaseq_pools: dict = {
        '1': ['V1V2', 'V4V5', 'ITS1'],
        '2': ['V2V3', 'V5V7'],
        '3': ['V3V4', 'V7V9']
    }

    demux_primers_dict: dict = []
    if args.specific_pools:
        region_list: list = []
        for pool in args.specific_pools:
            region_list += qiaseq_pools[pool]
        demux_primers_dict = {key: qiaseq_primers[key] for key in region_list}
    elif args.specific_regions:
        demux_primers_dict = {key: qiaseq_primers[key] for key in args.specific_regions}
    else:
        demux_primers_dict = {key: value for key, value in qiaseq_primers.items()}

    for file in args.input_path.glob('*_R1_*.fastq.gz'):
        perform_trim(file, args.output_path, demux_primers_dict)
        if args.concatenate_path:
            condense_files(file, args.output_path, args.concatenate_path)

def print_runtime(action) -> None:
    """ Return the time and some defined action. """
    print(f'[{time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())}] {action}')
# --------------------------------------------------
if __name__ == '__main__':
    main()
