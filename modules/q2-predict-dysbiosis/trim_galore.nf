process RUN_TRIMGALORE_SINGLE {
    input:
        tuple val(prefix), path(read1)

    output:
        tuple val(prefix), path("${prefix}_trimmed.fq.gz")

    script:
    """
    trim_galore \\
        --cores ${task.cpus} \\
        --output_dir . \\
        --gzip \\
        --basename ${prefix} \\
        ${read1}
    """
}

process RUN_TRIMGALORE_PAIR {
    input:
        tuple val(prefix), path(read1), path(read2)

    output:
        tuple val(prefix), path("${prefix}_val_1.fq.gz"), path("${prefix}_val_2.fq.gz")

    script:
    """
    trim_galore \\
        --paired \\
        --cores ${task.cpus} \\
        --output_dir . \\
        --basename ${prefix} \\
        ${read1} ${read2}
    """
}
