process SCORE_TABLE {
    tag "Final Gut Score Table"

    container 'docker.io/namlhs/io-gmwi2-pipeline:5.25'
    
    publishDir "${params.outdir}/final", mode: 'copy', overwrite: true

    input:
      path scores

    output:
      path 'gmwi2_scores_table.tsv', emit: scores_table

    script:
    """
    # write header
    echo -e "sample\\tgmwi2_score" > gmwi2_scores_table.tsv

    # loop over each staged file
    for f in ${scores}; do
      sample=\$(basename \"\$f\" _GMWI2.txt)
      score=\$(cat \"\$f\")
      echo -e \"\$sample\\t\$score\" >> gmwi2_scores_table.tsv
    done
    """
}
