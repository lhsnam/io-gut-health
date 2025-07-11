#!/usr/bin/env python
import os
import pandas as pd
import argparse

def read_metaphlan_file(filepath):
    df = pd.read_csv(filepath, sep='\t')
    # Change 'unclassified' to 'UNKNOWN' in clade_name column if it exists
    if 'clade_name' in df.columns:
        df['clade_name'] = df['clade_name'].replace('unclassified', 'UNKNOWN')
    df = df[['clade_taxid', 'estimated_number_of_reads_from_the_clade']]
    df = df[df['clade_taxid'].astype(str).str.isdigit() | (df['clade_taxid'].astype(str) == '-1')]
    df['estimated_number_of_reads_from_the_clade'] = pd.to_numeric(df['estimated_number_of_reads_from_the_clade'], errors='coerce').fillna(0)
    # Sum all rows with clade_taxid == -1
    df['clade_taxid'] = df['clade_taxid'].astype(str)
    df = df.groupby('clade_taxid', as_index=False)['estimated_number_of_reads_from_the_clade'].sum()
    df = df.set_index('clade_taxid')
    return df

def get_sample_name(filepath):
    basename = os.path.basename(filepath)
    if basename.endswith('_profile.txt'):
        return basename.split('_profile.txt')[0]
    else:
        return os.path.splitext(basename)[0]

def main():
    parser = argparse.ArgumentParser(description="Merge MetaPhlAn estimated reads tables.")
    parser.add_argument("-o", default="total_absolute_abundance.tsv", help="Output table file name (default: total_absolute_abundance.tsv)")
    parser.add_argument("-i", nargs='+', required=True, help="Input file names separated by space")
    args = parser.parse_args()

    output_file = args.o
    input_files = args.i

    sample_names = [get_sample_name(f) for f in input_files]
    dfs = [read_metaphlan_file(f) for f in input_files]

    merged = pd.concat(dfs, axis=1, join='outer')
    merged.columns = sample_names
    merged = merged.fillna(0)

    merged = merged.reset_index()
    merged.rename(columns={'clade_taxid': '#OTU ID'}, inplace=True)

    merged.to_csv(output_file, sep='\t', index=False)

if __name__ == "__main__":
    main()
