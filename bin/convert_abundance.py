#!/usr/bin/env python3
import argparse
import pandas as pd

def convert_to_relative_abundance(input_file):
    # Skip the first row (metadata)
    df = pd.read_csv(input_file, sep='\t', skiprows=1)

    # The first column is assumed to be OTU ID
    otu_column = df.columns[0]

    # Convert all numeric values (except the OTU ID column) from 0–100 to 0–1
    df.iloc[:, 1:] = df.iloc[:, 1:] / 100.0

    # Save to a fixed output filename
    output_file = "total_relative_abundance.tsv"
    df.to_csv(output_file, sep='\t', index=False)
    print(f"Converted file saved as: {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert percent abundance to relative abundance (0–1).")
    parser.add_argument("-i", "--input", required=True, help="Input TSV file with percent abundance values.")
    args = parser.parse_args()
    
    convert_to_relative_abundance(args.input)
