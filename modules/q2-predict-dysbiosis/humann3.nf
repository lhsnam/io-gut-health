process RUN_HUMANN {
    tag { prefix }

    container 'biobakery/humann:3.8'

    publishDir "${params.outdir}/humann/genefamilies",  mode: 'copy', overwrite: true, pattern: "${prefix}_genefamilies.tsv"
    publishDir "${params.outdir}/humann/pathabundance", mode: 'copy', overwrite: true, pattern: "${prefix}_pathabundance.tsv"
    publishDir "${params.outdir}/humann/pathcoverage",  mode: 'copy', overwrite: true, pattern: "${prefix}_pathcoverage.tsv"

    input:
      tuple val(prefix), path(read1), path(read2), path(chocophlan_db), path(uniref_db)

    output:
      path "${prefix}_genefamilies.tsv",  emit: genefamilies
      path "${prefix}_pathabundance.tsv", emit: pathabundance
      path "${prefix}_pathcoverage.tsv",  emit: pathcoverage

    script:
    """
    if [ ! -s "${read2}" ]; then
        echo "Running HUMAnN on single-end read"
        humann \\
          --input ${read1} \\
          --output . \\
          --nucleotide-database ${chocophlan_db} \\
          --protein-database ${uniref_db} \\
          --threads ${task.cpus}
    else
        echo "Running HUMAnN on paired-end reads: merging ${read1} + ${read2}"
        cat ${read1} ${read2} > ${prefix}_merged.fastq
        humann \\
          --input ${prefix}_merged.fastq \\
          --output . \\
          --nucleotide-database ${chocophlan_db} \\
          --protein-database ${uniref_db} \\
          --threads ${task.cpus}
    fi

    mv *_genefamilies.tsv  ${prefix}_genefamilies.tsv
    mv *_pathabundance.tsv ${prefix}_pathabundance.tsv
    mv *_pathcoverage.tsv  ${prefix}_pathcoverage.tsv
    """
}
