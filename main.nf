#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Check mandatory parameters
if ( !params.design ) {
    exit 1, "ERROR: Design samplesheet not specified. Please provide --design <path>"
}
ch_design = file(params.design, checkIfExists: true)

// Include modules
include { INPUT_CHECK } from './modules/input_check.nf'
include { DATABASE_PREPARATION } from './modules/database_preparation.nf'
include { RUN_GMWI2_SINGLE } from './modules/run_gmwi2.nf'
include { RUN_GMWI2_PAIR } from './modules/run_gmwi2.nf'
include { METAPHLAN_QIIMEPREP } from './modules/qiime/metaphlan_qiime.nf'
include { QIIME_IMPORT } from './modules/qiime/qiime_import.nf'
include { QIIME_DATAMERGE } from './modules/qiime/qiime_merge.nf'
include { SCORE_TABLE } from './modules/score_table.nf'
include { PLOT_SCORES } from './modules/plot_score.nf'
include { MARKER_MAP } from './modules/marker_map.nf'
include { MERGE_MARKER_MAP } from './modules/merge_marker.nf'

// MAIN workflow: validate, parse, and run GMWI2
workflow MAIN {
    take:
        samplesheet

    main:
        // 1. Input check and parsing the design sheet
        input_res = INPUT_CHECK(samplesheet)

        // 2. Prepare inputs: tuple as (meta, reads)
        gmwi_in = input_res.fastq.map { meta, reads -> tuple(meta, reads) }

        // 3. Split into single-end and paired-end
        gmwi_in_single = gmwi_in.filter { meta, reads -> meta.single_end?.toString() == 'true' }
            .map { meta, reads -> 
                def prefix = meta.run_accession ? "${meta.sample}_${meta.run_accession}" : meta.sample
                tuple(prefix, reads[0], file(params.database_location))
            }

        gmwi_in_pair = gmwi_in.filter { meta, reads -> !(meta.single_end?.toString() == 'true') }
            .map { meta, reads -> 
                def prefix = meta.run_accession ? "${meta.sample}_${meta.run_accession}" : meta.sample
                tuple(prefix, reads[0], reads[1], file(params.database_location))
            }

        // 4. Prepare database location channel
        // db_location_ch = Channel.value(file(params.database_location))

        // 5. Run GMWI2 for each case
        gmwi_res_single = RUN_GMWI2_SINGLE(gmwi_in_single)
        gmwi_res_pair   = RUN_GMWI2_PAIR(gmwi_in_pair)

        // 6. Merge results
        gmwi_res = [
            gmwi2_score: (gmwi_res_single.gmwi2_score ?: Channel.empty()).mix(gmwi_res_pair.gmwi2_score ?: Channel.empty()),
            gmwi2_taxa:  (gmwi_res_single.gmwi2_taxa  ?: Channel.empty()).mix(gmwi_res_pair.gmwi2_taxa  ?: Channel.empty()),
            metaphlan:   (gmwi_res_single.metaphlan   ?: Channel.empty()).mix(gmwi_res_pair.metaphlan   ?: Channel.empty())
        ]

    emit:
        gmwi2_scores = gmwi_res.gmwi2_score
        gmwi2_taxa   = gmwi_res.gmwi2_taxa
        metaphlan    = gmwi_res.metaphlan
}

workflow QIIME {
    take:
        gmwi2_scores
        gmwi2_taxa
        metaphlan

    main:
        qiime_profiles       = Channel.empty()
        qiime_taxonomy       = Channel.empty()
        ch_output_file_paths = Channel.empty()
        ch_warning_message   = Channel.empty()

        // Turn the Path-only channel into (prefix, file) tuples:
        def metaphlan_tuples = metaphlan.map { file ->
        // remove the "_metaphlan.txt" suffix to get your prefix
            def prefix = file.getName().replaceFirst(/_metaphlan\.txt$/, '')
            tuple(prefix, file)
        }

        // Now invoke the process with the correct shape
        qiime_prep = METAPHLAN_QIIMEPREP(metaphlan_tuples)
        qiime_profiles = qiime_profiles.mix( METAPHLAN_QIIMEPREP.out.mpa_biomprofile )
        qiime_taxonomy = qiime_taxonomy.mix( METAPHLAN_QIIMEPREP.out.taxonomy )

        QIIME_IMPORT ( qiime_profiles )

        QIIME_DATAMERGE( QIIME_IMPORT.out.relabun_qza.collect(), qiime_taxonomy.collect() , METAPHLAN_QIIMEPREP.out.profile.collect() )

        ch_output_file_paths = ch_output_file_paths.mix(
            QIIME_DATAMERGE.out.filtered_counts_collapsed_tsv.map{ "${params.outdir}/qiime_mergeddata/" + it.getName() }
            )
        QIIME_DATAMERGE.out.filtered_counts_collapsed_qza
            .ifEmpty('There were no samples or taxa left after filtering! Try lower filtering criteria or examine your data quality.')
            .filter( String )
            .set{ ch_warning_message }

    emit:
        qiime_profiles
        qiime_taxonomy
        ch_output_file_paths
        ch_warning_message
}

workflow FINAL_REPORT {
    take:
        gmwi2_scores
        gmwi2_taxa
        metaphlan

    main:
        scores_tbl = SCORE_TABLE( gmwi2_scores.collect() )

        stats_pre = metaphlan
            .combine(gmwi2_taxa)
            .map { mpa, coef ->
                def sample = mpa.baseName.replaceAll('_metaphlan\\.txt$', '')
                tuple(sample, mpa, coef)
            }

        db_ch = Channel.value( file(params.marker_db) )

        stats_in = stats_pre
            .combine(db_ch)
            .map { sample, mpa, coef, db ->
                tuple(sample, mpa, coef, db)
            }

        marker_map_files = MARKER_MAP(stats_in)

        all_marker_map = MERGE_MARKER_MAP( marker_map_files.collect() )

        plot_html = PLOT_SCORES( scores_tbl, all_marker_map )

    emit:
        all_marker_map
        plot_html
}



// Top-level workflow invocation
workflow {
    raw_sheet = Channel.fromPath(ch_design)
    MAIN(raw_sheet)

    QIIME(
        MAIN.out.gmwi2_scores,
        MAIN.out.gmwi2_taxa,
        MAIN.out.metaphlan
    )

    FINAL_REPORT(
        MAIN.out.gmwi2_scores,
        MAIN.out.gmwi2_taxa,
        MAIN.out.metaphlan,
    )
}
