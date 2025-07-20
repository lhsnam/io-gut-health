// Example Nextflow pipeline using the Q2 Predict Dysbiosis Docker container
nextflow.enable.dsl = 2

process PREDICT_DYSBIOSIS {
    tag "${meta.id}"
    label 'process_medium'
    container 'docker.io/namlhs/q2-predict-dysbiosis:7.25'
    
    input:
    tuple val(meta), path(species), path(pathways_strat), path(pathways_unstrat)
    val mode
    
    output:
    tuple val(meta), path("*_dysbiosis_results.csv"), emit: results
    path "versions.yml", emit: versions
    
    when:
    task.ext.when == null || task.ext.when
    
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    run_q2_predict_dysbiosis.py \\
        --species ${species} \\
        --pathways-stratified ${pathways_strat} \\
        --pathways-unstratified ${pathways_unstrat} \\
        --mode ${mode} \\
        --output ${prefix}_dysbiosis_results.csv \\
        ${args}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        q2-predict-dysbiosis: "7.25"
    END_VERSIONS
    """
}

workflow {
    // Example input channel
    input_ch = Channel.of([
        [id: 'sample1'], 
        file('test_real_samples/species.txt'), 
        file('test_real_samples/pathways_stratified.txt'), 
        file('test_real_samples/pathways_unstratified.txt')
    ])
    
    mode = 'full'
    
    PREDICT_DYSBIOSIS(input_ch, mode)
    
    PREDICT_DYSBIOSIS.out.results.view { meta, result ->
        "Sample ${meta.id}: ${result}"
    }
}
