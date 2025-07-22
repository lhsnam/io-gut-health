process RUN_GMWI2_SINGLE {
    label 'process_gmwi2'
    tag { prefix }

    container 'docker.io/namlhs/gmwi2-custom:7.25'

    publishDir "${params.outdir}/score",      mode: 'copy', overwrite: true, pattern: "${prefix}_GMWI2.txt"
    publishDir "${params.outdir}/taxa_coef",  mode: 'copy', overwrite: true, pattern: "${prefix}_GMWI2_taxa.txt"
    publishDir "${params.outdir}/metaphlan",  mode: 'copy', overwrite: true, pattern: "${prefix}_metaphlan.txt"

    input:
      tuple val(prefix), path(read1), path(db_location)

    output:
      path "${prefix}_GMWI2.txt",       emit: gmwi2_score
      path "${prefix}_GMWI2_taxa.txt",  emit: gmwi2_taxa
      path "${prefix}_metaphlan.txt",   emit: metaphlan

    script:
    """
    gmwi2 -f ${read1} --single -n ${task.cpus} -o ${prefix} -m ${db_location}/metaphlan-databases/ -g ${db_location}/genome-databases/GRCh38_noalt_as/
    """
}

process RUN_GMWI2_PAIR {
    label 'process_gmwi2'
    tag { prefix }

    container 'docker.io/namlhs/gmwi2-custom:7.25'

    publishDir "${params.outdir}/score",      mode: 'copy', overwrite: true, pattern: "${prefix}_GMWI2.txt"
    publishDir "${params.outdir}/taxa_coef",  mode: 'copy', overwrite: true, pattern: "${prefix}_GMWI2_taxa.txt"
    publishDir "${params.outdir}/metaphlan",  mode: 'copy', overwrite: true, pattern: "${prefix}_metaphlan.txt"

    input:
      tuple val(prefix), path(read1), path(read2), path(db_location)

    output:
      path "${prefix}_GMWI2.txt",       emit: gmwi2_score
      path "${prefix}_GMWI2_taxa.txt",  emit: gmwi2_taxa
      path "${prefix}_metaphlan.txt",   emit: metaphlan

    script:
    """
    gmwi2 -f ${read1} -r ${read2} -n ${task.cpus} -o ${prefix} -m ${db_location}/metaphlan-databases/ -g ${db_location}/genome-databases/GRCh38_noalt_as/
    """
}
