#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/*
 Ensure the GMWI2 Conda environment is created once before any process runs.
 Add the following to nextflow.config alongside this script:

    conda {
      enabled = true
    }
*/

// Default parameters
params.threads = params.threads ?: 8
params.outdir  = params.outdir  ?: './results'

// Check mandatory parameters
if ( !params.design ) {
    exit 1, "ERROR: Design samplesheet not specified. Please provide --design <path>"
}
ch_design = file(params.design, checkIfExists: true)

// Include input-check module
include { INPUT_CHECK } from './modules/input_check.nf'

// Process: filter out single-end samples and warn
process FILTER_SINGLE_END {
    tag "filter_single_end"

    input:
        path design_file

    output:
        path 'cleaned_samplesheet.csv', emit: samplesheet

    script:
    """
    # Warn for single-end entries (missing R2)
    awk -F',' 'NR>1 && \$3 == "" { print "WARNING: Ignoring single-end sample: " \$1 }' ${design_file} >&2
    # Keep only header + paired-end rows
    awk -F',' 'NR==1 || \$3 != "" { print }' ${design_file} > cleaned_samplesheet.csv
    """
}

// Process: run GMWI2, with retries and skip on failure
process RUN_GMWI2 {
    tag { prefix }
    publishDir params.outdir, mode: 'copy'

    cpus params.threads
    conda 'bioconda::gmwi2=1.6'

    // Retry up to 3 times, then skip on further failure
    errorStrategy { task.attempt <= 3 ? 'retry' : 'ignore' }
    maxRetries 3
    maxForks 1

    input:
        tuple val(prefix), path(read1), path(read2)

    output:
        path "${prefix}_GMWI2.txt",       emit: gmwi2_score
        path "${prefix}_GMWI2_taxa.txt",  emit: gmwi2_taxa
        path "${prefix}_metaphlan.txt",   emit: metaphlan

    script:
    """
    gmwi2 -f ${read1} -r ${read2} -n ${task.cpus} -o ${prefix}
    """
}

// MAIN workflow: validate, parse, and run GMWI2
workflow MAIN {
    take:
        samplesheet

    main:
        // 1. Input check and parsing the design sheet
        input_res = INPUT_CHECK(samplesheet)

        // 2. Prepare inputs: determine prefix per sample
        gmwi_in = input_res.fastq.map { meta, reads ->
            def prefix = meta.run_accession ? "${meta.sample}_${meta.run_accession}" : meta.sample
            tuple(prefix, reads[0], reads[1])
        }

        // 3. Scatter GMWI2 runs
        gmwi_res = RUN_GMWI2(gmwi_in)

    emit:
        gmwi2_scores = gmwi_res.gmwi2_score
        gmwi2_taxa   = gmwi_res.gmwi2_taxa
        metaphlan    = gmwi_res.metaphlan
}

// Top-level workflow invocation
workflow {
    raw_sheet     = Channel.fromPath(ch_design)
    cleaned_sheet = raw_sheet | FILTER_SINGLE_END
    MAIN(cleaned_sheet)
}
