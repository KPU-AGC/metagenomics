#!/usr/bin/env python3
__descritpion__= \
"""
The purpose of this script is to generate a metadata table for use in qiime analyses using the dataset's samplesheet as input
"""
__author__="Pat Taylor"
__version__="0.1.0"
__comments__="...Hang on to your butts"
# Importing libraries for making command-line arguments
# ---------------------------------------------------
from argparse import (
    Namespace,
    ArgumentParser,
    RawTextHelpFormatter)
from pathlib import Path
import pandas as pd
import io
# Import the Sample sheet from the dataset
# ---------------------------------------------------
def get_args() -> Namespace:
    """
    Get the path for the sample sheet and assign output path
    - Parameters:
        * Input sample sheet path
        * Output sample metadata path
    - Returns:
        * get_args: Namespace
    """
    parser = ArgumentParser(
        description = __descritpion__,
        epilog = f"v{__version__}, by {__author__}, '{__comments__}'",
        formatter_class = RawTextHelpFormatter)
    parser.add_argument('-M', '--manifest_input',
                        metavar = '<PATH>',
                        type =  Path,
                        help = 'Path and filename (i.e., "import_manifest.tsv") to the import manifest used for importing data into qiime for this dataset',
                        required=True)
    parser.add_argument('-S', '--samplesheet_input',
                        metavar = '<PATH>',
                        type =  Path,
                        help = 'Path and filename (i.e., "Samplesheet.csv") to the sample sheet used for the MiSeq run that generated this dataset',
                        required=True)
    parser.add_argument('-O', '--output_sample_metadata',
                        metavar = '<PATH>',
                        type = Path,
                        help = 'Path and filename for the sample metadata file to be used with qiime',
                        required=True)
    return parser.parse_args()
# Extract the sample ID's
# ---------------------------------------------------
def get_manifest_IDs(MANIFEST_PATH: Path) -> pd.DataFrame:
    """
    Extract the sample identifers from the input manifest file
    - Parameters:
        * MANIFEST_PATH: Path
    - Returns:
        * QIIME_SAMPLE_IDs: pd.DataFrame
    """
    SAMPLE_ID_EXTRACT = pd.read_csv(MANIFEST_PATH, sep='\t')
    QIIME_SAMPLE_IDs = SAMPLE_ID_EXTRACT[['sample-id']].sort_values(by='sample-id')
    QIIME_SAMPLE_IDs = QIIME_SAMPLE_IDs[QIIME_SAMPLE_IDs['sample-id'] != '#q2:types'].reset_index(drop=True)
    print(QIIME_SAMPLE_IDs)
    return QIIME_SAMPLE_IDs
def get_samplesheet_IDs(SAMPLESHEET_PATH: Path) -> pd.DataFrame:
    """
    Extract the sample identifers from the input sample sheet
    - Parameters:
        * INPUT_SAMPLESHEET: Namespace
    - Returns:
        * SAMPLE_ID_LIST_SORTED: pd.DataFrame
    """ 
    with open(SAMPLESHEET_PATH) as INPUT_SAMPLESHEET:
        # Jump down to the actual table with sample IDs (indexes are going to be dropped)
        for line in INPUT_SAMPLESHEET:
            if line.strip() == "[Data]":
                break
        # Read the file right to the end
        SAMPLE_LINES = INPUT_SAMPLESHEET.readlines()
        # Extract all the table from the sample sheet
        SAMPLE_ID_EXTRACT = pd.read_csv(io.StringIO(''.join(SAMPLE_LINES)))
        SAMPLE_ID_LIST_SORTED = SAMPLE_ID_EXTRACT[['Sample_ID']].sort_values(by='Sample_ID')
        return SAMPLE_ID_LIST_SORTED
# Generate the sample metadata file
# ---------------------------------------------------
def main() -> None:
    """
    Merge the two dataframes generated together to get the sample metadata dataframe
    - Parameters:
        * None
    - Returns:
        * None
    """
    ARGS = get_args()
    QIIME_SAMPLE_IDs = get_manifest_IDs(ARGS.manifest_input)
    SAMPLE_ID_LIST_SORTED = get_samplesheet_IDs(ARGS.samplesheet_input)
    DATAFRAMES = [QIIME_SAMPLE_IDs, SAMPLE_ID_LIST_SORTED]
    SAMPLE_METADATA = pd.concat(DATAFRAMES, axis=1)
    QIIME_METADATA_FORMATTING = {'sample-id': '#q2:types', 'Sample_ID': 'categorical'}
    QIIME_METADATA_FORMATTING_DF = pd.DataFrame([QIIME_METADATA_FORMATTING])
    SAMPLE_METADATA_FORMATTED = pd.concat([SAMPLE_METADATA.iloc[:0], QIIME_METADATA_FORMATTING_DF, SAMPLE_METADATA.iloc[1:]]).reset_index(drop=True)
    SAMPLE_METADATA_FORMATTED.to_csv(ARGS.output_sample_metadata, sep='\t',index=False)
if __name__ == "__main__":
    main()