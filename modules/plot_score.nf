process PLOT_SCORES {
    tag "PLOT_SCORES"

    container 'docker.io/namlhs/io-gmwi2-pipeline:5.25'
    publishDir "${params.outdir}/plots", mode: 'copy', overwrite: true
    input:
      path scores_table

    output:
      path 'gmwi2_scores_bar.html', emit: scores_plot

    script:
    """
    # call the helper script
    plot_scores.py --input ${scores_table} --output gmwi2_scores_bar.html
    """
}
