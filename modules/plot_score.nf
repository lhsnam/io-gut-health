process PLOT_SCORES {
    tag "PLOT_SCORES"
    container 'namlhs/io-gmwi2-pipeline:5.25'

    input:
      path scores_table    // e.g. gmwi2_scores_table.tsv
      path all_marker_map     // e.g. all_taxon_stats.tsv

    output:
      path 'gmwi2_dashboard.html', emit: plot_html

    script:
    """
    plot_scores.py \
      --input  ${scores_table} \
      --stats  ${all_marker_map} \
      --output gmwi2_dashboard.html
    """
}
