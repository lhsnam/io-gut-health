#!/usr/bin/env python
import pandas as pd
import argparse

#the following function takes in all taxonomy files and create a non-redundant taxonomy file
def qiime_taxmerge(taxonomylist, output):
    dfs = []
    for tax in taxonomylist:
        df = pd.read_csv(tax, sep="\t")
        dfs.append(df)
    merged_taxon = pd.concat(dfs).drop_duplicates()
    merged_taxon.to_csv(output, index=False, sep="\t")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="""Merge together all taxonomy file output""")
    parser.add_argument(dest="taxonomylist", nargs='+', type=str, help="list of taxonomic files")
    parser.add_argument("-o", "--output", dest="output", type=str, default="merged_taxonomy.tsv", help="output file name")
    args = parser.parse_args()
    qiime_taxmerge(args.taxonomylist, args.output)
