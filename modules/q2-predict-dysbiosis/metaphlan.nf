process RUN_METAPHLAN {
    tag { prefix }

    container 'quay.io/biocontainers/metaphlan:3.0.13--pyhb7b1952_0'

    publishDir "${params.outdir}/metaphlan", mode: 'copy', overwrite: true, pattern: "${prefix}_metaphlan.txt"

    input:
        tuple val(prefix), path(read1), path(read2), path(metaphlan_db)

    output:
        path "${prefix}_metaphlan.txt", emit: metaphlan_profile

    script:
    """
    if [ ! -s "${read2}" ] || [ "${read2}" = "/dev/null" ]; then
        echo "Running MetaPhlAn 3 on single-end"
        metaphlan \\
            ${read1} \\
            --index mpa_v30_CHOCOPhlAn_201901 \\
            --bowtie2db ${metaphlan_db} \\
            --nproc ${task.cpus} \\
            --input_type fastq \\
            --add_viruses \\
            --unknown_estimation \\
            --force \\
            --no_map \\
            -t rel_ab_w_read_stats \\
            -o ${prefix}_metaphlan.txt
    else
        echo "Running MetaPhlAn 3 on paired-end"
        metaphlan \\
            ${read1},${read2} \\
            --index mpa_v30_CHOCOPhlAn_201901 \\
            --bowtie2db ${metaphlan_db} \\
            --nproc ${task.cpus} \\
            --input_type fastq \\
            --add_viruses \\
            --unknown_estimation \\
            --force \\
            --no_map \\
            -t rel_ab_w_read_stats \\
            -o ${prefix}_metaphlan.txt
    fi
    """
}
