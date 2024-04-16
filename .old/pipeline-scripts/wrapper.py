#!/usr/bin/env python3
__description__ = "Purpose: Helper script to demultiplex phased primers using a subprocess wrapper."
__author__ = "Erick Samera"
__version__ = "1.2.1"
__comment__ = 'stable'
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
        description=f"{__description__}",
        epilog=f"v{__version__} : {__author__} | {__comment__}",
        formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        'input_path',
        type=Path,
        help='path of directory containing .fastq.gz')
    parser.add_argument(
        'output_path',
        type=Path,
        help='path of output directory')
    parser.add_argument(
        'output_path',
        type=Path,
        help='path of output directory')

    args = parser.parse_args()

    args.input_path = args.input_path.resolve()
    args.output_path = args.output_path.resolve()
    if not args.output_path.exists():
        args.output_path.mkdir(parents=True, exist_ok=True)

    return args
# --------------------------------------------------
def qiime_import(input_path_arg: Path, output_path_arg: Path) -> None:
    """
    import qiime
    """

    output_file = "imported_demux_paired_end.qza"

    with subprocess.Popen([
        'qiime', 'tools', 'import',
        '--type', 'SampleData[PairedEndSequencesWithQuality]',
        '--input-path', f'{input_path_arg}',
        '--output-path', f'{output_path_arg.joinpath(output_file)}',
        '--input-format', 'CasavaOneEightSingleLanePerSampleDirFmt'],
    stdout=subprocess.PIPE) as output:
        x = output.communicate()[0]
        print(output.returncode)
# --------------------------------------------------
def main():
    """
    asdfasdf
    """
    #input_path = Path()
    args = get_args()

    qiime_import(args.input_path, args.output_path)
# --------------------------------------------------
if __name__=="__main__":
    main()