#!/usr/bin/env python3
__description__ =\
"""
Purpose: To generate a summative .csv file from amr-finder outputs.
"""
__author__ = "Erick Samera"
__version__ = "1.0.0"
__comments__ = "stable"
# =============================================================================
from argparse import (
    Namespace,
    ArgumentParser,
    RawTextHelpFormatter)
from pathlib import Path
# =============================================================================
import pandas as pd
import csv
# =============================================================================
def get_args() -> Namespace:
    """ Get command-line arguments """

    parser = ArgumentParser(
        description=f"{__description__}",
        epilog=f"v{__version__} : {__author__} | {__comments__}",
        formatter_class=RawTextHelpFormatter,
        allow_abbrev=False)
    parser.add_argument('input_dir',
        metavar="PATH",
        type=Path,
        help=f"input dir containing .csv files from amr-finder")
    parser.add_argument('-o', '--output-dir',
        metavar="PATH",
        type=Path,
        default=None,
        help=f"output dir of csv file")

    args = parser.parse_args()
    # parser errors and processing
    # =========================================================================
    if not args.output_dir: args.output_dir = Path.cwd()

    return args
# =============================================================================
def _generate_summary(args: Namespace) -> None:
    """
    Generate a summary table.
    """
    summary_data: dict = {}

    for file in [file for file in args.input_dir.glob('*.csv') if '_mut' not in file.stem]:
        sample_id: str = file.stem
        summary_data[sample_id] = {}
        with open(file) as csv_file:
            csv_reader = csv.DictReader(csv_file)
            for row in csv_reader:
                sample_value = (
                    float(row['% Coverage of reference sequence'])
                  + float(row['% Identity to reference sequence'])) / 200
                characteristic = row['Sequence name']
                summary_data[sample_id][characteristic] = sample_value

    pd.DataFrame.from_dict(summary_data, orient='index').fillna(0).to_csv(args.output_dir.joinpath('output.csv'))
# =============================================================================
def main() -> None:
    """ Insert docstring here """
    args = get_args()
    _generate_summary(args)
    return None
# =============================================================================
if __name__ == '__main__':
    main()
