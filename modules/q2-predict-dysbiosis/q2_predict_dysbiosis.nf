process Q2_PREDICT_DYSBIOSIS {
    tag "${meta.id}"
    
    container 'docker.io/namlhs/q2-predict-dysbiosis:7.25'
    
    publishDir "${params.outdir}/q2_predict_dysbiosis", mode: 'copy', overwrite: true
    
    input:
        tuple val(meta), path(species), path(pathways_strat), path(pathways_unstrat)
        val mode
        path model_file

    output:
        tuple val(meta), path("dysbiosis_results.csv"), emit: results
    
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    run_q2_predict_dysbiosis.py \\
        --species ${species} \\
        --pathways-stratified ${pathways_strat} \\
        --pathways-unstratified ${pathways_unstrat} \\
        --mode ${mode} \\
        --output dysbiosis_results.csv \\
        ${args}
    """
}