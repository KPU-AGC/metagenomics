#!/usr/bin/env python3
"""
Author : Erick Samera
Date   : 2022-11-08
Purpose: Process a directory of IonTorrent-formatted fastq and create a metadata file.
"""
__author__ = "Erick Samera"
__version__ = "1.0.0"
__comments__ = "it works"
# imports
# --------------------------------------------------
from argparse import (
    Namespace,
    ArgumentParser,
    ArgumentDefaultsHelpFormatter)
from pathlib import Path
# --------------------------------------------------
def get_args() -> Namespace:
    """ Get command-line arguments """

    parser = ArgumentParser(
        description="Process a directory of .fastq(.gz) files and create a metadata file",
        epilog=f"v{__version__} : {__author__} | {__comments__}",
        formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        'input_path',
        type=Path,
        help='path of directory containing .fastq(.gz)')

    args = parser.parse_args()

    args.input_path = args.input_path.resolve()
    if not args.input_path.exists():
        parser.error("Input directory doesn't exist!")

    return args
# --------------------------------------------------
def _both_reads_contained(list_files_arg: list, list_samples_arg: list) -> bool:
    """
    Performs a sanity check, just makes sure that both R1 and R2 are in the set of files.

    Parameters:
        list_files_arg: list
            a list of files in the directory
        list_samples_arg: list
            a list of samples that are scraped from the list of files
    
    Returns:
        True if both R1 and R2 exist for each of the samples, else False
    """

    for sample in list_samples_arg:
        if (f'{sample}_S1_L001_R1_001.fastq.gz' not in list_files_arg) or (f'{sample}_S1_L001_R2_001.fastq.gz' not in list_files_arg):
            return False
    return True
def _generate_metadata_file(dir_path_arg: Path) -> None:
    """
    Function to extract information from the filename

    Parameters:
        dir_path_arg: Path
            the path of the directory to iterate through

    Returns:
        (dict): dictionary of filename information processed and ready to be passed
    """

    list_of_files: list = [file.name for file in dir_path_arg.glob('*.gz')]
    unique_samples: list = list(set([file.split('_')[0] for file in list_of_files]))

    if not _both_reads_contained(list_of_files, unique_samples):
        print("Not every file seems to have both R1 and R2. Check this before proceeding.")
    elif _both_reads_contained(list_of_files, unique_samples):
        with open(dir_path_arg.joinpath('metadata.tab'), 'w') as metadata_output:
            metadata_output.write("sample-id\t\n")
            metadata_output.write("#q2:types\t\n")
            for sample in unique_samples:
                metadata_output.write(f"{sample}\t\n")
    return None
# --------------------------------------------------
def main() -> None:
    """ main """
    args = get_args()

    _generate_metadata_file(args.input_path)
# --------------------------------------------------
if __name__ == '__main__':
    main()
