#!/usr/bin/env python3
"""
Purpose: Helper script to create consistent OTU tables and taxonomy to the species level.
"""
__author__ = "Erick Samera"
__version__ = "2.0.0"
__comments__ = "very stable"

# --------------------------------------------------
from argparse import (
    Namespace,
    ArgumentParser,
    ArgumentDefaultsHelpFormatter)
from pathlib import Path
# --------------------------------------------------
import time
import csv
import pandas as pd
from rapidfuzz import process, fuzz
# --------------------------------------------------
def get_args() -> Namespace:
    """ Get command-line arguments """

    parser = ArgumentParser(
        #usage='%(prog)s',
        description="Helper script to create consistent OTU tables and taxonomy to the species level.",
        epilog=f"v{__version__} : {__author__} | {__comments__}",
        formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        'input_path',
        type=Path,
        help="path of OTU file (.csv)")
    parser.add_argument(
        '-o',
        '--out',
        dest='output_path',
        metavar='FILEPATH',
        type=Path,
        help="path of output OTU file (.csv)")
    # --------------------------------------------------
    group_custom_regions = parser.add_argument_group(
        title='NCBI taxonomy database information (required)')
    group_custom_regions.add_argument(
        '--nodes',
        dest='nodes_path',
        metavar='FILEPATH',
        type=Path,
        required=True,
        help='path of NCBI nodes.dmp file')
    group_custom_regions.add_argument(
        '--names',
        dest='names_path',
        metavar='FILEPATH',
        type=Path,
        required=True,
        help='path of NCBI names.dmp file')
    group_debug = parser.add_argument_group(
        title='debugging arguments')
    group_debug.add_argument(
        '--output-mismatches',
        dest='output_mismatches_path',
        metavar='FILEPATH',
        type=Path,
        help='path to output taxonomic values that did not pass threshold')
    group_debug.add_argument(
        '--scorer',
        dest='scorer',
        metavar='NAME',
        choices=['ratio', 'QRatio', 'partial_ratio'],
        type=str,
        default='partial_ratio',
        help='scorer for fuzzy matching [ratio, QRatio, partial_ratio]')
    group_debug.add_argument(
        '--match-db',
        dest='match_db',
        metavar='DATABASE',
        choices=['taxonomy', 'all'],
        type=str,
        default='taxonomy',
        help='taxonomy: match species against species db, etc.; all: search everything (use ratio scorer, very computationally intensive)')
    group_debug.add_argument(
        '--match-threshold',
        dest='match_threshold',
        metavar='INT',
        type=int,
        default=99,
        help='0..100, threshold for fuzzy matches')

    args = parser.parse_args()

    # parser errors and processing
    # --------------------------------------------------
    if not args.input_path.resolve().exists():
        parser.error("Input doesn't exist.")

    return args
# --------------------------------------------------
def _process_csv(args, path_arg: Path, txid_dict_arg: dict) -> dict:
    """
    Function processes a (.csv) file and returns dictionary of processed data.

    Parameters:
        path_arg (Path): path of the OTU .csv file
        txid_dict_arg: NCBI txid dict

    Returns:
        (dict): processed dictionary to be output as DataFrame
    """

    start_time = time.time()
    _processed_otus: list = []

    taxonomy_levels: dict = {
        6: ['species', 'strain'],
        5: ['genus'],
        4: ['family'],
        3: ['order'],
        2: ['class'],
        1: ['phylum'],
        0: ['kingdom', 'superkingdom']
    }
    scorer: dict = {
        'ratio': fuzz.ratio,
        'QRatio': fuzz.QRatio,
        'partial_ratio': fuzz.partial_ratio
    }

    def _compare_with_dict(taxon_str_arg: str, taxon_level_arg: int) -> dict:
        """
        Function takes a taxon name and compares it to a dictionary of txid at a given taxonomy level to get the txid.

        Parameters:
            taxon_str_arg (str): taxon name
            taxon_level_arg (int): taxon level, [0, 6], 6 being the most specific

        Returns:
            best_match (dict): dictionary of best matched txid
                score:  match score
                txid:   txid from NCBI txid_dict_arg
                name:   scientific name of match
        """

        total_matches: list = []
        match_db: list = []

        if args.match_db == 'taxonomy':
            match_db = taxonomy_levels[taxon_level_arg]
        elif args.match_db == 'all':
            for i in range(7):
                match_db += taxonomy_levels[i]

        for taxonomy_synonym in match_db:
            fuzzy_match = process.extract(taxon_str_arg, list(txid_dict_arg['names'][taxonomy_synonym].keys()), scorer=scorer[args.scorer], limit=1)
            match_name = fuzzy_match[0][0]
            match_score = fuzzy_match[0][1]
            match_txid = txid_dict_arg['names'][taxonomy_synonym][match_name]
            match = {'score': match_score, 'txid': match_txid, 'name': match_name}
            total_matches.append(match)
        best_match = sorted(total_matches, key=lambda match: match['score'], reverse=True)[0]
        
        if round(best_match['score']) >= args.match_threshold:
            return best_match
        else:
            if args.output_mismatches_path:
                with open(args.output_mismatches_path, 'a', encoding='utf8') as mismatches_file:
                    mismatches_file.write(f"{taxon_str_arg}\t{taxon_level_arg}\t{best_match['name']}\t{best_match['txid']}\t{best_match['score']}\n")
            return False
    def _convert_taxonomy(taxonomy_list_arg: list) -> tuple:
        """
        Function produces a tuple of taxonomy.

        Parameters:
            taxonomy_list_arg (list): list of txid taxonomy to parse

        Returns:
            (tuple): tuple of txid translated to scientific name and rank
        """
        return tuple({'name': txid_dict_arg['nodes'][txid]['name'], 'rank': txid_dict_arg['nodes'][txid]['rank']} for txid in taxonomy_list_arg)
    with open(path_arg, 'r', encoding='utf8') as otu_csv_file:

        # skip the header
        all_lines: list = [value for value in csv.DictReader(otu_csv_file)]

        # initialize the result counter for printing
        result_count: int  = 0

        for line in all_lines:
            otu_entry_dict: dict = {'Name': line['Name']}

            result_count += 1
            taxonomy = [taxon.strip() for taxon in line["Taxonomy"].split(';')]
            samples = [sample.replace("Abundance", "").strip() for sample in list(line.keys()) if "Abundance" in sample and not "Combined" in sample]

            # initialize the matched taxonomy result
            matched_taxonomy_result: str = ''

            # starting from the most narrowed taxonomy, try to find a match
            for taxonomy_i, taxonomy_level_str in enumerate(taxonomy[::-1]):
                # counting backwards from the list, also make the numbers count down
                actual_taxonomy_level = len(taxonomy) - taxonomy_i - 1

                # don't match taxonomy if it doesn't even pass the string filtering
                filtered_strings = any((
                    ('uncultured' in taxonomy_level_str.lower()),
                    ('metagenome' in taxonomy_level_str.lower()),
                    ('unknown' in taxonomy_level_str.lower()),
                    ('unclassified' in taxonomy_level_str.lower()),
                    ('unidentified' in taxonomy_level_str.lower()),
                    (not taxonomy_level_str)
                    ))
                if not filtered_strings:
                    taxonomy_level_str = taxonomy_level_str.split('(')[0].strip()
                    taxonomy_level_str = taxonomy_level_str.replace('[', '').replace(']', '')
                    matched_taxonomy_result = _compare_with_dict(taxonomy_level_str, actual_taxonomy_level)
                    if matched_taxonomy_result:
                        break
                else:
                    continue

            if matched_taxonomy_result:
                taxonomy_list = _convert_taxonomy(txid_dict_arg['nodes'][matched_taxonomy_result['txid']]['taxonomy'][::-1])

                # eukaryotes are classified in superkingdom eukaryota
                # bacteria and archaea are classified into kingdom prokaryota

                if 'superkingdom' in [taxon['rank'] for taxon in taxonomy_list]:
                    allowed_taxonomy = ('superkingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species')
                else:
                    allowed_taxonomy = ('kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species')

                pre_processed_taxonomy = [taxon['name'] for taxon in taxonomy_list if taxon['rank'] in allowed_taxonomy]

                # add 'unclassified' taxonomy entries
                if len(pre_processed_taxonomy) < len(allowed_taxonomy):
                    processed_taxonomy = pre_processed_taxonomy
                    highest_level = pre_processed_taxonomy[-1]
                    for i in range(len(allowed_taxonomy) - len(processed_taxonomy)):
                        processed_taxonomy.append(f'Unclassified {highest_level}')
                else:
                    processed_taxonomy = pre_processed_taxonomy
            elif not matched_taxonomy_result:
                processed_taxonomy = 'N/A'

            otu_entry_dict['Taxonomy'] = '; '.join(processed_taxonomy)
            otu_entry_dict['Sequence'] = line['Sequence']

            for sample in samples:
                sample_key = f"{sample} Abundance"
                otu_entry_dict[sample] = int(line[sample_key])

            if result_count % 500 == 0:
                print_runtime(f'Completed: {result_count}/{len(all_lines)} | ({round(time.time() - start_time, 3)} s. elapsed)')

            _processed_otus.append(otu_entry_dict)
    return _processed_otus
def _create_txid_dict(names_dmp_path_arg: Path, nodes_dmp_path_arg: Path) -> dict:
    """
    Function creates a dictionary based on NCBI names and nodes.

    Parameters:
        names_dmp_path_arg (Path): path of names.dmp file
        nodes_dmp_path_arg (Path): path of nodes.dmp file

    Returns:
        (dict): processed txid dictionary
            nodes: node dictionary, keys are txid
            names: names dictionary, keys are taxonomic ranks, subkeys are scientific names
    """
    # initialize txid_name and node dictionaries
    _names_dict: dict = {}
    _nodes_dict: dict = {}
    with open(names_dmp_path_arg, 'r', encoding='utf8') as names_dmp_file, \
         open(nodes_dmp_path_arg, 'r', encoding='utf8') as nodes_dmp_file:

        # for each line in the node file, create a txid entry with taxonomy info
        for line in nodes_dmp_file.readlines():
            line_args = [line_arg.strip() for line_arg in line.split('|')]
            txid = int(line_args[0])
            _nodes_dict[txid] = {
                'rank': line_args[2],
                'parent_node': int(line_args[1])
                }

        # for the scientific or equivalent names in name file, create an entry with txid
        for line in names_dmp_file.readlines():
            line_args = [line_arg.strip() for line_arg in line.split('|')]
            name_check = any((
                'scientific name' in line_args,
                'equivalent name' in line_args,
                'synonym' in line_args))
            if name_check:
                taxon_name = line_args[1]
                txid = int(line_args[0])
                if 'scientific name' in line_args:
                    _nodes_dict[txid]['name'] = taxon_name
                try:

                    _names_dict[_nodes_dict[txid]['rank']][taxon_name] = txid
                except KeyError:
                    _names_dict[_nodes_dict[txid]['rank']] = {}
                    _names_dict[_nodes_dict[txid]['rank']][taxon_name] = txid

    # post-processing of the node dictionary to create taxonomy
    for entry, _ in _nodes_dict.items():
        _nodes_dict[entry]['taxonomy']: list = [entry]

        current_level = _nodes_dict[entry]['parent_node']
        while _nodes_dict[entry]['taxonomy'][-1] != 1:
            _nodes_dict[entry]['taxonomy'].append(current_level)
            current_level = _nodes_dict[current_level]['parent_node']
    print_runtime(f'Created NCBI txid database .')
    return {'nodes': _nodes_dict, 'names': _names_dict}
# --------------------------------------------------
def main() -> None:
    """ Insert docstring here """

    args = get_args()
    txid_dict = _create_txid_dict(args.names_path, args.nodes_path)

    if args.output_mismatches_path:
        with open(args.output_mismatches_path, 'w', encoding='utf8') as mismatches_file:
            mismatches_file.write(f"taxon_query\ttaxon_level\tbest_match\tbest_match_score\tbest_match_score\n")
    otu_DataFrame = pd.DataFrame(_process_csv(args, args.input_path, txid_dict))
    otu_DataFrame_columns = ['Name', 'Taxonomy'] \
        + [column for column in otu_DataFrame.columns.to_list() if not column in ('Name', 'Taxonomy', 'Sequence')]\
        + ['Sequence']
    if args.output_path:
        otu_DataFrame[otu_DataFrame_columns].to_csv(args.output_path, index=False)
    else:
        otu_DataFrame[otu_DataFrame_columns].to_csv('output.csv', index=False)
    print_runtime(f'Produced resulting OTU table .')
    return None
def print_runtime(action) -> None:
    """ Return the time and some defined action. """
    print(f'[{time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())}] {action}')
    return None
# --------------------------------------------------
if __name__ == '__main__':
    main()
