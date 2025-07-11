#!/usr/bin/env python3
"""
Script: marker_map.py

For each sample, pick the top 10 species-level taxa present in both MetaPhlAn report and the reference
database (skipping any missing) and then any extra species-level taxa from the GMWI2 coefficient file
only if they exist in the database. Finally, retrieve median and mean for each species from the db CSV,
filter to those shared by both user & db, round all numeric values to 1 decimal, and output a TSV.

Usage:
  python3 marker_map.py \
    --mpa <sample>_metaphlan.txt \
    --coef <sample>_GMWI2_taxa.txt \
    --db gmrepo_254.csv \
    --sample SAMPLE_ID \
    --output <sample>_marker_map.tsv
"""
import argparse
import pandas as pd

def main():
    p = argparse.ArgumentParser(description="Compute taxon stats for a sample.")
    p.add_argument('--mpa',    required=True, help="MetaPhlAn output (.txt)")
    p.add_argument('--coef',   required=True, help="GMWI2 taxa coefficient file (.txt)")
    p.add_argument('--db',     required=True, help="GMrepo database CSV with 'Taxon','mean','median'")
    p.add_argument('--sample', required=True, help="Sample identifier")
    p.add_argument('--output', required=True, help="Output TSV filename")
    args = p.parse_args()

    # helper to extract species name
    def species_name(full):
        if '|s__' in full:
            return full.split('|')[-1].replace('s__','')
        else:
            return full

    # 1) load MetaPhlAn, species-level
    mp = pd.read_csv(args.mpa, sep='\t', comment='#', header=None,
                     names=['clade_name','tax_id','rel_abundance','coverage','read_count'])
    
    # Export mp DataFrame to a TSV file for inspection
    mp.to_csv(f"{args.sample}_mpa_full.tsv", sep='\t', index=False)
    
    # Detect the single-row UNKNOWN or unclassified case:
    if mp.shape[0] == 1 and mp.iloc[0]['clade_name'] in ['UNKNOWN', 'unclassified']:
        unk = mp.iloc[0]
        df = pd.DataFrame([{
            'sample':         args.sample,
            'species':        mp.iloc[0]['clade_name'],
            'user_abundance': unk['rel_abundance'],
            'db_median':      pd.NA,
            'db_mean':        pd.NA
        }])
        # write NAs as the literal string "NA"
        df.to_csv(
            args.output,
            sep='\t',
            index=False,
            na_rep='NA'
        )
        return

    sp = mp[ mp['clade_name'].astype(str).str.contains(r"\|s__") ]
    sp = sp.assign(species=sp['clade_name'].map(species_name))

    # 2) load database
    db = pd.read_csv(args.db)
    if 'Taxon' not in db.columns:
        raise KeyError("Expected 'Taxon' column in database CSV")
    db = db.set_index('Taxon')

    # 3) build top10: take from sp sorted, but only those present in db
    top_list = []
    for _, row in sp.sort_values('rel_abundance', ascending=False).iterrows():
        if row['species'] in db.index:
            top_list.append({'taxon': row['clade_name'], 'user_abundance': row['rel_abundance'], 'species': row['species']})
            if len(top_list) >= 10:
                break
    top_df = pd.DataFrame(top_list)
    top_df.to_csv(f"{args.sample}_top_species.tsv", sep='\t', index=False)

    # 4) extras from coef
    coef = pd.read_csv(args.coef, sep='\t')
    coef_sp = coef[ coef['taxa_name'].str.contains(r"\|s__") ]
    coef_sp = coef_sp.assign(species=coef_sp['taxa_name'].map(species_name))

    # Export coef_sp to a TSV file for inspection
    coef_sp.to_csv(f"{args.sample}_coef_species.tsv", sep='\t', index=False)
    # drop those in top and only keep those present in db
    extra_df = coef_sp[ ~coef_sp['species'].isin(top_df['species']) & coef_sp['species'].isin(db.index) ]

    extra_df = extra_df.rename(columns={'taxa_name':'taxon'})[['taxon']]
    extra_df = extra_df.assign(user_abundance=pd.NA, species=extra_df['taxon'].map(species_name))

    # 5) combine
    all_df = pd.concat([top_df, extra_df], ignore_index=True)

    # 6) merge with db stats
    stats = db[['mean','median']].rename(columns={'mean':'db_mean','median':'db_median'})
    result = all_df.set_index('species').join(stats, how='left').reset_index()

    # 7) format sample prefix
    sample_prefix = args.sample.split('_')[0]
    result.insert(0, 'sample', sample_prefix)

    # 8) reorder cols
    cols = ['sample','species','user_abundance','db_median','db_mean']
    result = result.loc[:, cols]

    # 9) filter to those with both user and db values
    result = result.dropna(subset=['user_abundance','db_median','db_mean'])

    # 10) round numeric columns to 3 decimal
    result['user_abundance'] = result['user_abundance'].round(3)
    result['db_median']      = result['db_median'].round(3)
    result['db_mean']        = result['db_mean'].round(3)

    # write final file
    result.to_csv(args.output, sep='\t', index=False)

if __name__ == '__main__':
    main()
