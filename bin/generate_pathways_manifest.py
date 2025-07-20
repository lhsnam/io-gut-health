#!/usr/bin/env python3

import os
import argparse
import pandas as pd
from glob import glob

def merge_tables(input_dir, suffix, index_col, output_file):
    files = glob(os.path.join(input_dir, f'*{suffix}.tsv'))
    if not files:
        raise FileNotFoundError(f"No files found in {input_dir} with suffix {suffix}")

    merged_df = None

    for f in files:
        sample_id = os.path.basename(f).replace(suffix + '.tsv', '')
        df = pd.read_csv(f, sep='\t', comment='#', index_col=0)
        df = df.loc[~df.index.str.startswith('#')]  # drop header lines
        df = df[[df.columns[0]]]  # keep first column only (abundance)
        df.columns = [sample_id]  # rename column to sample_id

        if merged_df is None:
            merged_df = df
        else:
            merged_df = merged_df.join(df, how='outer')

    merged_df = merged_df.fillna(0).sort_index(axis=1)
    merged_df.index.name = index_col
    merged_df.to_csv(output_file, sep='\t')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate Q2-PREDICT formatted pathway manifest tables.')
    parser.add_argument('--genefamilies_dir', required=False, help='Directory with *_genefamilies.tsv files')
    parser.add_argument('--pathabundance_dir', required=True, help='Directory with *_humann_pathabundance.tsv files')
    parser.add_argument('--pathcoverage_dir', required=False, help='Directory with *_humann_pathcoverage.tsv files')
    parser.add_argument('--output_dir', required=True, help='Output directory')

    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    # Merge stratified (pathabundance) table
    merge_tables(
        input_dir=args.pathabundance_dir,
        suffix='_pathabundance',
        index_col='Pathway',
        output_file=os.path.join(args.output_dir, 'pathways_stratified.txt')
    )

    # Merge unstratified table: remove stratified rows
    def filter_unstratified(path):
        df = pd.read_csv(path, sep='\t', comment='#', index_col=0)
        return df[~df.index.str.contains('\\|')]

    unstratified_df = None
    for f in glob(os.path.join(args.pathabundance_dir, '*_pathabundance.tsv')):
        sample_id = os.path.basename(f).replace('_pathabundance.tsv', '')
        df = filter_unstratified(f)
        df = df[[df.columns[0]]]  # abundance
        df.columns = [sample_id]

        if unstratified_df is None:
            unstratified_df = df
        else:
            unstratified_df = unstratified_df.join(df, how='outer')

    unstratified_df = unstratified_df.fillna(0).sort_index(axis=1)
    unstratified_df.index.name = 'Pathway'
    unstratified_df.to_csv(os.path.join(args.output_dir, 'pathways_unstratified.txt'), sep='\t')
