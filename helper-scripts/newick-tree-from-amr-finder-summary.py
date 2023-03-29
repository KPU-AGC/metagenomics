#!/usr/bin/env python3
__description__ =\
"""
Purpose: To generate a distance matrix and tree.
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
import numpy as np
from skbio import DistanceMatrix
from skbio.tree import nj
# =============================================================================
def get_args() -> Namespace:
    """ Get command-line arguments """

    parser = ArgumentParser(
        description=f"{__description__}",
        epilog=f"v{__version__} : {__author__} | {__comments__}",
        formatter_class=RawTextHelpFormatter,
        allow_abbrev=False)
    parser.add_argument('input_path',
        metavar="PATH",
        type=Path,
        help=f"input summary .csv file")

    args = parser.parse_args()
    # parser errors and processing
    # --------------------------------------------------

    return args
# =============================================================================
def _sum_matrices(_input_summary_dict: dict) -> np.array:
    """
    Function sums the input and returns a summed aray.
    """    
    initialized_matrix: list = [[0*53]*53]
    for matrix in _input_summary_dict.values():
        initialized_matrix += matrix
    return initialized_matrix
def _create_distance_matrix(_input_dict: dict) -> list:
    """
    Create a distance matrix from a dictionary of {sample: value}.
    """
    matrix = []
    for key1, value1 in _input_dict.items():
        distances = []
        for key2, value2 in _input_dict.items():
            distances.append(abs(float(value1)-float(value2)))
        matrix.append(distances)
    return np.array(matrix)
def _get_samples(_input_file: Path) -> list:
    """
    Function returns a list of samples.
    """
    samples_list: list = []
    with open(_input_file, encoding='UTF-8') as input_file:
        for line in input_file.readlines():
            sample_id: str = line.split(',')[0]
            if sample_id: samples_list.append(sample_id)
    return samples_list
def _generate_summary_matrix(args: Namespace) -> dict:
    """
    Generate a summary table.
    """

    matrices: dict = {}
    with open(args.input_path, encoding='UTF-8') as input_file:
        header = [header_value.strip() for header_value in input_file.readline().strip().split(',') if header_value]
        values = [line.strip() for line in input_file.readlines()]
        for i, header_name in enumerate(header):
            input_distance_matrix_dict = {}
            for line in values:
                sample_id = line.split(',')[0]
                sample_value = line.split(',')[i+1]
                input_distance_matrix_dict[sample_id] = sample_value
            matrices[header_name] = _create_distance_matrix(input_distance_matrix_dict)
    return matrices
# =============================================================================
def main() -> None:
    """ Insert docstring here """
    args = get_args()
    
    samples_list = _get_samples(args.input_path)
    matrices_dict: dict = _generate_summary_matrix(args)
    summated_matrix: np.matrix = _sum_matrices(matrices_dict)

    distance_matrix_object = DistanceMatrix(summated_matrix, samples_list)
    neighbor_joining_tree = nj(distance_matrix_object, result_constructor=str)
    print(neighbor_joining_tree)
    return None
# =============================================================================
if __name__ == '__main__':
    main()
