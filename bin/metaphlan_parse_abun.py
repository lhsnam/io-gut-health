#!/usr/bin/env python

import argparse
import pandas as pd

def metaphlan_profileparse(mpa_profiletable, label):
    # Process MetaPhlAn3 input table
    # For relative abundance: remove all entries that are not on species level
    profile = pd.read_csv(mpa_profiletable, sep="\t", comment='#')
    profile = profile[["clade_name", "relative_abundance", "NCBI_tax_id"]]

    # Clean all entries that are not on the species level
    profile.columns = ["clade_name", label, "NCBI_tax_id"]
    profile = profile[profile["clade_name"].str.contains("s__") == True]
    profile = profile[profile["clade_name"].str.contains("t__") == False]
    # Output only Feature ID (NCBI_tax_id) and abundance
    profile_out = pd.DataFrame({
        "Feature ID": profile["NCBI_tax_id"].str.split('|').str[-1],
        label: profile[label]
    })
    profile_out.to_csv(label + "_relabun_parsed_mpaprofile.txt", sep="\t", index=False)

    # Formatting supplemental taxonomy table needed by QIIME2
    # Column names MUST be "Feature ID", "Taxon"
    taxonomy = pd.DataFrame({
        "Feature ID": profile["NCBI_tax_id"].str.split('|').str[-1],
        "Taxon": profile["clade_name"].str.replace("|", ";", regex=False)
    })

    taxonomy.to_csv(label + "_profile_taxonomy.txt", sep="\t", index=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="""Parse MetaPhlAn3 table""")
    parser.add_argument("-t", "--mpa_table", dest="mpa_profiletable", type=str, help="MetaPhlAn assigned reads")
    parser.add_argument("-l", "--label", dest="label", type=str, help="Sample label")
    args = parser.parse_args()
    metaphlan_profileparse(args.mpa_profiletable, args.label)
