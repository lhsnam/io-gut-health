#!/usr/bin/env python
"""
Parse a MetaPhlAn3 profile table to extract species-level abundances
and generate QIIME2-compatible outputs.
"""

import argparse
import pandas as pd


def metaphlan_profileparse(mpa_profiletable, label):
    """
    Parse a MetaPhlAn3 profile table to extract species-level rel. abundances
    and generate supplemental taxonomy and abundance tables for QIIME2.

    Args:
        mpa_profiletable (str): Path to the MetaPhlAn3 profile table (TSV).
        label (str): Sample label to use for output file naming and abundance.

    Outputs:
        - <label>_relabun_parsed_mpaprofile.txt: TSV with Feature ID and abundance.
        - <label>_profile_taxonomy.txt: TSV with Feature ID and taxonomy.
    """
    # Read MetaPhlAn3 profile, dropping comment lines
    profile = pd.read_csv(mpa_profiletable, sep="\t", comment='#')

    # Check for 100% UNKNOWN or unclassified case (single row with clade_name UNKNOWN or unclassified)
    if profile.shape[0] == 1 and profile.iloc[0]['clade_name'] in ['UNKNOWN', 'unclassified']:
        unk = profile.iloc[0]
        tax_id = unk['clade_taxid']
        abundance = unk['relative_abundance']
        # If clade_name is 'unclassified', change to 'UNKNOWN'
        taxon_name = 'UNKNOWN' if unk['clade_name'] == 'unclassified' else unk['clade_name']
        # Create abundance table matching standard format: Feature ID and sample label
        zero_abun = pd.DataFrame({
            'Feature ID': [str(tax_id)],
            label:        [abundance]
        })
        zero_abun.to_csv(
            f"{label}_relabun_parsed_mpaprofile.txt", sep="\t", index=False
        )
        # Create taxonomy table stub: tax_id and UNKNOWN
        zero_tax = pd.DataFrame({
            'Feature ID': [str(tax_id)],
            'Taxon':      [taxon_name]
        })
        zero_tax.to_csv(
            f"{label}_profile_taxonomy.txt", sep="\t", index=False
        )
        return

    # Standard processing: keep only species-level entries
    profile = profile[['clade_name', 'relative_abundance', 'clade_taxid']]
    profile.columns = ['clade_name', 'abundance', 'clade_taxid']
    # select species (s__) but not strain (t__), and include UNKNOWN or unclassified
    profile = profile[
        (
            profile["clade_name"].str.contains('s__') & ~profile["clade_name"].str.contains('t__')
        ) |
        (profile["clade_name"].isin(['UNKNOWN', 'unclassified']))
    ]
    profile.loc[profile["clade_name"] == "unclassified", "clade_name"] = "UNKNOWN"

    # Output only Feature ID (clade_taxid) and abundance
    profile_out = pd.DataFrame({
        "Feature ID": profile["clade_taxid"].str.split("|").str[-1],
        label: profile["abundance"]
    })
    profile_out.to_csv(
        f"{label}_relabun_parsed_mpaprofile.txt", sep="\t", index=False
    )

    # Formatting supplemental taxonomy table needed by QIIME2
    # Column names MUST be "Feature ID", "Taxon"
    taxonomy = pd.DataFrame({
        "Feature ID": profile["clade_taxid"].str.split('|').str[-1],
        "Taxon": profile["clade_name"].str.replace("|", ";", regex=False)
    })
    taxonomy.to_csv(
        f"{label}_profile_taxonomy.txt", sep="\t", index=False
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Parse MetaPhlAn3 table"
    )
    parser.add_argument(
        "-t", "--mpa_table", dest="mpa_profiletable",
        type=str, help="MetaPhlAn assigned reads"
    )
    parser.add_argument(
        "-l", "--label", dest="label",
        type=str, help="Sample label"
    )
    args = parser.parse_args()
    metaphlan_profileparse(args.mpa_profiletable, args.label)
