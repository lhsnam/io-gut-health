process QIIME_DATAMERGE {

    container 'quay.io/qiime2/core:2023.9'

    publishDir "${params.outdir}/qiime_mergeddata", mode: 'copy', overwrite: true, pattern: "*.csv"
    publishDir "${params.outdir}/qiime_mergeddata", mode: 'copy', overwrite: true, pattern: "species.txt"

    input:
    path(abs_qza)
    path(taxonomy)

    output:
    path('merged_filtered_counts.qza')           , emit: filtered_counts_qza
    path('merged_taxonomy.qza')                  , optional: true, emit: taxonomy_qza
    path('merged_filtered_counts_collapsed.qza') , optional: true, emit: filtered_counts_collapsed_qza
    path('merged_filtered_counts_collapsed.tsv') , optional: true, emit: filtered_counts_collapsed_tsv
    path('*.qza')
    path('merged_filtered_counts.tsv')           , optional: true, emit: count_table
    path('total_relative_abundance.csv')         , optional: true, emit: relative_abundance_total
    path('total_absolute_abundance.csv')         , optional: true, emit: absolute_abundance_total
    path('species.txt')                          , optional: true, emit: species_relative_abundance

    script:
    """
    qiime feature-table merge \
        --i-tables $abs_qza \
        --o-merged-table merged_raw_counts.qza

    qiime feature-table filter-samples \
        --i-table merged_raw_counts.qza \
        --p-min-frequency 1 \
        --o-filtered-table merged_counts_filter-samples.qza
    
    qiime feature-table filter-features \
        --i-table merged_counts_filter-samples.qza \
        --p-min-frequency 1 \
        --p-min-samples 1 \
        --o-filtered-table merged_filtered_counts.qza
    
    qiime tools export \
        --input-path merged_filtered_counts.qza \
        --output-path merged_filtered_counts_out

    biom summarize-table -i merged_filtered_counts_out/feature-table.biom > biom_table_summary.txt
    SAMPLES=\$(grep 'Num samples' biom_table_summary.txt | sed 's/Num samples: //')
    FEATURES=\$(grep 'Num observations' biom_table_summary.txt | sed 's/Num observations: //')

    if [ "\$SAMPLES" -gt 0 ] && [ "\$FEATURES" -gt 0 ]
    then
        biom convert -i merged_filtered_counts_out/feature-table.biom -o merged_filtered_counts.tsv --to-tsv

        qiime_taxmerge.py $taxonomy
        qiime tools import \
            --input-path merged_taxonomy.tsv \
            --type 'FeatureData[Taxonomy]' \
            --input-format TSVTaxonomyFormat \
            --output-path merged_taxonomy.qza

        qiime taxa collapse \
            --i-table merged_filtered_counts.qza \
            --i-taxonomy merged_taxonomy.qza \
            --p-level 7 \
            --o-collapsed-table merged_filtered_counts_collapsed.qza

        qiime tools export \
            --input-path merged_filtered_counts_collapsed.qza \
            --output-path merged_filtered_counts_collapsed_out
        biom convert -i merged_filtered_counts_collapsed_out/feature-table.biom -o merged_filtered_counts_collapsed.tsv --to-tsv
    fi

    convert_abundance.py -i-id merged_filtered_counts.tsv -i-species merged_filtered_counts_collapsed.tsv
    """
}