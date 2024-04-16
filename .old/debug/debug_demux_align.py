#!/usr/bin/env python3
"""
Author : Erick Samera
Date   : 2022-11-08
Purpose: Process a directory of demultiplexed .fastq(.gz) files and create a metadata file.
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
        'clc_demux_input',
        type=Path,
        help='path of directory containing .fastq(.gz)')
    parser.add_argument(
        'phased_demux_input',
        type=Path,
        help='path of directory containing .fastq(.gz)')
    args = parser.parse_args()

    args.input_path = args.input_path.resolve()
    if not args.input_path.exists():
        parser.error("Input directory doesn't exist!")

    return args
# --------------------------------------------------

# --------------------------------------------------
def main() -> None:
    """ main """
    args = get_args()
    print(args)
# --------------------------------------------------
if __name__ == '__main__':
    main()
