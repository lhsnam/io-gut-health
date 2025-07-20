#!/usr/bin/env python3
import argparse
import pandas as pd

def convert_to_relative_abundance(input_file):
    # Skip the first row (metadata)
    df = pd.read_csv(input_file, sep='\t', skiprows=1)

    first_col = df.columns[0]
    df.rename(columns={first_col: "NCBI_ID"}, inplace=True)

    # Convert all numeric values from 0–100 to 0–1
    df.iloc[:, 1:] = df.iloc[:, 1:] / 100.0

    # Save to a fixed output filename
    output_file = "total_relative_abundance.csv"
    df.to_csv(output_file, sep=',', index=False)
    print(f"Converted file saved as: {output_file}")

def convert_species_relative_abundance(input_file):
    df = pd.read_csv(input_file, sep='\t', skiprows=1)

    # Accept both '#OTU ID' and 'OTU_ID'
    otu_col = None
    for col in df.columns:
        if col.strip() in ['OTU_ID', '#OTU ID']:
            otu_col = col
            break
    if otu_col is None:
        raise ValueError("First column must be named 'OTU_ID' or '#OTU ID'.")

    # Extract string after 's__' in OTU column (if present)
    df['species'] = df[otu_col].str.extract(r's__(.*)')

    # If species is missing, UNKNOWN, or unclassified, set as 'unclassified'
    df['species'] = df['species'].fillna('unclassified')
    df['species'] = df['species'].replace(
        to_replace=r'^(UNKNOWN|unknown|unclassified)?$', value='unclassified', regex=True
    )

    # Save species names to 'species.txt'
    df['species'].dropna().to_csv('species.txt', index=False, header=False)
    print("Species names saved as: species.txt")

    # Convert all numeric values from 0–100 to 0–1 (excluding OTU and species columns)
    numeric_cols = [col for col in df.columns if col not in [otu_col, 'species']]
    df[numeric_cols] = df[numeric_cols] / 100.0

    # Save relative abundance table with 'species' as the first column (remove OTU column)
    output_file = "species.txt"
    cols_to_save = ['species'] + numeric_cols
    df[cols_to_save].to_csv(output_file, sep='\t', index=False)
    print(f"Converted file saved as: {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert percent abundance to relative abundance (0–1).")
    parser.add_argument("-i-id", "--input-id", required=True, help="Input TSV file with percent abundance values with ID.")
    parser.add_argument("-i-species", "--input-species", required=True, help="Input TSV file with percent abundance values for species.")
    args = parser.parse_args()

    convert_to_relative_abundance(args.input_id)
    convert_species_relative_abundance(args.input_species)
