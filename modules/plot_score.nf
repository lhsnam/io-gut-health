process PLOT_SCORES {
    tag "Visualize GMWI2 Scores"
    
    container 'namlhs/io-gmwi2-pipeline:5.25'

    publishDir "${params.outdir}/final", mode: 'copy', overwrite: true
    
    input:
      path scores_table
      path all_marker_map

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
