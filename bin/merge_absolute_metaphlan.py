#!/usr/bin/env python
import argparse
import pandas as pd
import os

def extract_ncbi_id(clade_taxid):
    try:
        parts = str(clade_taxid).split('|')
        # Get last non-empty numeric part
        for part in reversed(parts):
            if part.strip().isdigit():
                return int(part)
        return -1
    except Exception:
        return -1

def parse_input_files(file_paths):
    result = {}
    all_taxids = set()

    for path in file_paths:
        sample_name = os.path.basename(path).split('_')[0]
        df = pd.read_csv(path, sep='\t')

        # Normalize unclassified entries to behave like UNKNOWN
        df['clade_name'] = df['clade_name'].fillna('')
        df.loc[df['clade_name'].str.lower() == 'unclassified', 'clade_taxid'] = -1
        df.loc[df['clade_name'].str.lower() == 'unclassified', 'clade_name'] = 'UNKNOWN'

        # Filter: keep only rows with "s__" or "UNKNOWN"
        df = df[df['clade_name'].str.contains("s__") | (df['clade_name'] == "UNKNOWN")]

        # Extract standardized NCBI_ID
        df['NCBI_ID'] = df['clade_taxid'].apply(extract_ncbi_id)

        # Aggregate by NCBI_ID
        df = df.groupby('NCBI_ID')['estimated_number_of_reads_from_the_clade'].sum().reset_index()
        df = df.rename(columns={'estimated_number_of_reads_from_the_clade': sample_name})

        result[sample_name] = df.set_index('NCBI_ID')[sample_name]
        all_taxids.update(df['NCBI_ID'].values)

    # Combine all results
    all_taxids = sorted(all_taxids)
    combined_df = pd.DataFrame(index=all_taxids)

    for sample, series in result.items():
        combined_df[sample] = series

    combined_df.fillna(0, inplace=True)
    combined_df.index.name = 'NCBI_ID'
    return combined_df.reset_index()

def main():
    parser = argparse.ArgumentParser(description='Aggregate species-level absolute abundance from MetaPhlAn outputs.')
    parser.add_argument('-i', '--input', nargs='+', required=True, help='Input files separated by space')
    parser.add_argument('-o', '--output', default='total_absolute_abundance.tsv', help='Output file name')

    args = parser.parse_args()

    combined_df = parse_input_files(args.input)
    combined_df.to_csv(args.output, sep='\t', index=False)
    print(f"Saved combined table to: {args.output}")

if __name__ == '__main__':
    main()
