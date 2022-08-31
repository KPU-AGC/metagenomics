#!/usr/bin/env python3
"""
Author : Erick Samera
Date   : 2022-08-20
Purpose: Re-process IonTorrent-formatted .fastq/.fastq.gz to casava and produce sample metadata.csv
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
            reformats it to casava format.',
        #usage='%(prog)s',
        epilog='v1.0.0 : Erick Samera',
        formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        'input_path',
        type=Path,
        help='path of directory containing fastq/fastq.gz')
    parser.add_argument(
        '-b',
        '--barcodes',
        dest='barcodes_path',
        type=Path,
        required=True,
        help='path of ion_express_barcodes.csv')

    args = parser.parse_args()

    args.input_path = args.input_path.resolve()
    args.barcodes = args.barcodes_path.resolve()

    return args
# --------------------------------------------------
def rename_and_create_metadata(processed_name_info_arg: dict):
    """
    Function to rename and create metadata based on information processed from name.

    Parameters:
        processed_name_info_arg (dict): the name information that was processed

    Returns:
        (dict):
            new_name (str): the new name including suffix to rename
            metadata_to_write (str): metadata to write into metadata csv
    """

    # casava format is as follows:
    # L2S357_15_L001_R1_001.fastq.gz
    new_name = f"{processed_name_info_arg['sample_name']}_{processed_name_info_arg['barcode_sequence']}_L{processed_name_info_arg['lane_number']}_R1_001{processed_name_info_arg['extra_info']['filetype']}"

    metadata_to_write = f"{processed_name_info_arg['sample_name']}\t "\
                      + f"{processed_name_info_arg['barcode_sequence']}\t "\
                      + f"{processed_name_info_arg['extra_info']['year']}\t "\
                      + f"{processed_name_info_arg['extra_info']['start_month']}\t "\
                      + f"{processed_name_info_arg['extra_info']['start_day']}\t "\
                      + f"{processed_name_info_arg['extra_info']['end_month']}\t "\
                      + f"{processed_name_info_arg['extra_info']['end_day']}"\

    return {'new_name': new_name, 'metadata_to_write': metadata_to_write}

def process_barcodes(barcodes_path_arg: Path) -> dict:
    """
    Function to process IonTorrent barcodes

    Parameters:
        barcodes_path_arg (Path): path to the barcodes.csv file

    Returns:
        (dict): dictionary containing barcode sequences with barcode numbers as the key
    """

    with open(barcodes_path_arg, 'r', encoding='UTF8') as barcodes_file:

        barcodes_dict = {}

        # define the headers in the .csv file
        lines = barcodes_file.readlines()
        headers = [header.strip() for header in lines[4].split(',') if header.strip() != '']

        # define the lines that will actually be processed
        lines_to_process = lines[5:]
        for line in lines_to_process:
            # separates line into barcode data
            barcode_data =[line_info for line_info in line.split(',') if line_info != '\n'][:len(headers)]
            barcode_index = int(barcode_data[0].split('_')[1])
            barcodes_dict[barcode_index] = {}
            for i, header in enumerate(headers[1:]):
                try:
                    maybe_numerical = int(barcode_data[i+1])
                    barcodes_dict[barcode_index][header] = maybe_numerical
                except ValueError:
                    barcodes_dict[barcode_index][header] = barcode_data[i+1]
    return barcodes_dict

def process_name(filename_arg: Path, barcodes_dict_arg: dict) -> dict:
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

    # fake lane number
    lane_number = file_info[-1].zfill(3)

    # retrieve barcode
    try:
        ion_express_name_index = [index for index, value in enumerate(file_info) if 'IonXpress' in value][0]
    except IndexError:
        # basic error handle
        print("ERROR: Can't seem to process this. Has this file already been processed?")
        print(f"File: {filename_arg.name}")
        _exit(1)
    ion_express_index = int(file_info[ion_express_name_index+1])
    barcode_sequence = barcodes_dict_arg[ion_express_index]['sequence']

    # retrieve sample name
    sample_info_list = [info.strip() for info in '-'.join(file_info[:ion_express_name_index]).split('-') if info != '']
    find_2019 = [index for index, value in enumerate(sample_info_list) if '2019' in value][0]
    sample_name = '-'.join(sample_info_list[:find_2019])

    # other_info
    run_info = 'T'.join(sample_info_list[find_2019:]).split('T')
    filetype = filename_arg.suffix if filename_arg.suffix == '.fastq' else filename_arg.name[-9:]
    other_information = {
        'year': run_info[0],
        'start_month': run_info[1],
        'start_day': run_info[2],
        'end_month': run_info[3],
        'end_day': run_info[4],
        'filetype': filetype
    }

    processed_name_info = {
        'lane_number': lane_number,
        'barcode_sequence': barcode_sequence,
        'sample_name': sample_name,
        'extra_info': other_information
    }

    return processed_name_info
# --------------------------------------------------
def main() -> None:
    """ main """
    args = get_args()

    barcodes_dict = process_barcodes(args.barcodes_path)
    with open(args.input_path.parent.joinpath('metadata.tsv'), 'w', encoding='UTF8') as output_metadata_file:
        top_header = "sample-id\tbarcode-sequence\tyear\tstart-month\tstart-day\tend-month\tend-day"
        types_header = "q2:types\tcategorical\tnumeric\tnumeric\tnumeric\tnumeric\tnumeric"
        output_metadata_file.write(f'{top_header}\n')
        output_metadata_file.write(f'{types_header}\n')
        for file in args.input_path.glob('*.fastq*'):
            file_info = rename_and_create_metadata(process_name(file, barcodes_dict))
            output_metadata_file.write(f"{file_info['metadata_to_write']}\n")
            rename(file, file.parent.joinpath(file_info['new_name']))
# --------------------------------------------------
if __name__ == '__main__':
    main()
