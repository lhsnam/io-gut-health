#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Check mandatory parameters
if ( !params.design ) {
    exit 1, "ERROR: Design samplesheet not specified. Please provide --design <path>"
}
ch_design = file(params.design, checkIfExists: true)

// Include input-check module
include { INPUT_CHECK } from './modules/input_check.nf'
include { FILTER_SINGLE_END } from './modules/filter_single_end.nf'
include { DATABASE_PREPARATION } from './modules/database_preparation.nf'
include { RUN_GMWI2 } from './modules/run_gmwi2.nf'

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

        // DATA_PREPARATION: Prepare MetaPhlAn database once before GMWI2 runs
        db_prepared = DATABASE_PREPARATION(trigger: true)

        // 3. Scatter GMWI2 runs
        gmwi_res = RUN_GMWI2(gmwi_in, db_prepared.db_ready)

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
