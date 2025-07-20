process Q2_MANIFEST {
    tag "generate_manifest_tables"

    container 'docker.io/namlhs/io-gmwi2-pipeline:5.25'

    publishDir "${params.outdir}/q2_manifest", mode: 'copy'

    input:
      path(genefamilies_list)
      path(pathabundance_list)
      path(pathcoverage_list)

    output:
      path "pathways_stratified.txt",    emit: stratified_table
      path "pathways_unstratified.txt",  emit: unstratified_table

    script:
    """
    mkdir -p inputs/genefamilies inputs/pathabundance inputs/pathcoverage

    for f in ${genefamilies_list}; do cp \$f inputs/genefamilies/; done
    for f in ${pathabundance_list}; do cp \$f inputs/pathabundance/; done
    for f in ${pathcoverage_list}; do cp \$f inputs/pathcoverage/; done

    generate_pathways_manifest.py \\
        --genefamilies_dir inputs/genefamilies \\
        --pathabundance_dir inputs/pathabundance \\
        --pathcoverage_dir inputs/pathcoverage \\
        --output_dir .
    """
}
