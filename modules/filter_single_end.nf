process FILTER_SINGLE_END {
    tag "Remove Single-End Samples"

    container 'docker.io/namlhs/io-gmwi2-pipeline:5.25'

    input:
        path design_file

    output:
        path 'cleaned_samplesheet.csv', emit: samplesheet

    script:
    """
    # Warn for single-end entries (missing R2)
    awk -F',' 'NR>1 && \$3 == "" { print "WARNING: Skipping single-end sample: " \$1 }' ${design_file} >&2
    # Keep only header + paired-end rows
    awk -F',' 'NR==1 || \$3 != "" { print }' ${design_file} > cleaned_samplesheet.csv
    """
}