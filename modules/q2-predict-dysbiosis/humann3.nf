process RUN_HUMANN {
    tag "${prefix}"
    
    cpus 4

    container 'quay.io/biocontainers/humann:3.7--pyh7cba7a3_0'

    publishDir "${params.outdir}/humann/genefamilies",  mode: 'copy', overwrite: true, pattern: "${prefix}_genefamilies.tsv"
    publishDir "${params.outdir}/humann/pathabundance", mode: 'copy', overwrite: true, pattern: "${prefix}_pathabundance.tsv"
    publishDir "${params.outdir}/humann/pathcoverage",  mode: 'copy', overwrite: true, pattern: "${prefix}_pathcoverage.tsv"

    input:
        tuple val(prefix), path(read1), path(read2), path(metaphlan_profile), path(database_location)

    output:
        path "${prefix}_genefamilies.tsv",  emit: genefamilies
        path "${prefix}_pathabundance.tsv", emit: pathabundance
        path "${prefix}_pathcoverage.tsv",  emit: pathcoverage
        path "${prefix}.log",               emit: log

    script:
    """
    humann_config \\
        --update database_folders nucleotide gut-score-db/humann-databases/${params.humann_nucleotide_db}

    humann_config \\
        --update database_folders protein gut-score-db/humann-databases/${params.humann_protein_db}

    if [ ! -s "${read2}" ] || [ "${read2}" = "/dev/null" ]; then
        echo "Single-end input: ${read1}"
        if [[ "${read1}" == *.gz ]]; then
            zcat "${read1}" > "${prefix}_input.fastq"
            input_reads="${prefix}_input.fastq"
        else
            input_reads="${read1}"
        fi
        humann \\
            --input \$input_reads \\
            --input-format fastq \\
            --taxonomic-profile ${metaphlan_profile} \\
            --o-log "${prefix}.log" \\
            --output . \\
            --threads ${task.cpus}
    else
        echo "Paired-end detected, merging reads"
        if [[ "${read1}" == *.gz ]]; then
            zcat "${read1}" > temp_read1.fastq
            READ1_FILE="temp_read1.fastq"
        else
            READ1_FILE="${read1}"
        fi
        if [[ "${read2}" == *.gz ]]; then
            zcat "${read2}" > temp_read2.fastq
            READ2_FILE="temp_read2.fastq"
        else
            READ2_FILE="${read2}"
        fi
        cat "\$READ1_FILE" "\$READ2_FILE" > "${prefix}_merged.fastq"
        humann \\
            --input ${prefix}_merged.fastq \\
            --input-format fastq \\
            --taxonomic-profile ${metaphlan_profile} \\
            --o-log "${prefix}.log" \\
            --output . \\
            --threads ${task.cpus}
    fi

    mv *_genefamilies.tsv  ${prefix}_genefamilies.tsv
    mv *_pathabundance.tsv ${prefix}_pathabundance.tsv
    mv *_pathcoverage.tsv  ${prefix}_pathcoverage.tsv
    """
}
