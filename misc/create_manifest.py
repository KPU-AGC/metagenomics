#!/usr/bin/env python3
"""
Author : Erick Samera
Date   : 2022-08-31
Purpose: Process a directory of IonTorrent-formatted fastq and create a manifest file.
"""

# imports
# --------------------------------------------------
from argparse import (
    Namespace,
    ArgumentParser,
    ArgumentDefaultsHelpFormatter)
from pathlib import Path
from os import rename, _exit
# --------------------------------------------------
def get_args() -> Namespace:
    """ Get command-line arguments """

    parser = ArgumentParser(
        description='Program takes a directory of IonTorrent-formatted fastq/fastq.gz files and \
            creates a manifest file.',
        #usage='%(prog)s',
        epilog='v1.0.0 : Erick Samera',
        formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        'input_path',
        type=Path,
        help='path of directory containing fastq/fastq.gz')

    args = parser.parse_args()

    args.input_path = args.input_path.resolve()

    return args
# --------------------------------------------------

def process_name(filename_arg: Path) -> str:
    """
    Function to extract information from the filename
    Parameters:
        filename_arg (Path): .fastq/fastq.gz file to be processed
        barcodes_dict_arg (dict): dictionary containing barcodes
    Returns:
        (dict): dictionary of filename information processed and ready to be passed
    """

    if filename_arg.name.endswith('.fastq'):
        file_info = filename_arg.stem.split('_')
    elif filename_arg.name.endswith('.gz'):
        file_info = filename_arg.stem[:-6].split('_')

    # retrieve barcode
    try:
        ion_express_name_index = [index for index, value in enumerate(file_info) if 'IonXpress' in value][0]
    except IndexError:
        # basic error handle
        print("ERROR: Can't seem to process this. Has this file already been processed?")
        print(f"File: {filename_arg.name}")
        _exit(1)

    sample_id = '_'.join(file_info[ion_express_name_index:])
    absolute_path = filename_arg
    return f'{sample_id}\t{absolute_path}'
# --------------------------------------------------
def main() -> None:
    """ main """
    args = get_args()

    with open(args.input_path.joinpath('manifest.tsv'), 'w', encoding='UTF8') as output_metadata_file:
        top_header = "sample-id\tforward-absolute-filepath\treverse-absolute-filepath"
        output_metadata_file.write(f'{top_header}\n')
        for file in args.input_path.glob('*.fastq*'):
            output_metadata_file.write(f"{process_name(file)}\n")
# --------------------------------------------------
if __name__ == '__main__':
    main()
