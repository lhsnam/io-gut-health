// Process: run GMWI2 with retries and sequential execution
process RUN_GMWI2 {
    tag { prefix }
    publishDir "${params.outdir}/", mode: 'copy', overwrite: true

    input:
        tuple val(prefix), path(read1), path(read2)
        val db_ready

    output:
        path "score/${prefix}_GMWI2.txt",       emit: gmwi2_score
        path "taxa_coef/${prefix}_GMWI2_taxa.txt",  emit: gmwi2_taxa
        path "metaphlan/${prefix}_metaphlan.txt",   emit: metaphlan

    script:
    """
    gmwi2 -f ${read1} -r ${read2} -n ${task.cpus} -o ${prefix}
    """
}
