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
include { RUN_HUMANN } from './modules/q2-predict-dysbiosis/humann3.nf'
include { RUN_METAPHLAN } from './modules/q2-predict-dysbiosis/metaphlan.nf'
include { RUN_TRIMGALORE_SINGLE } from './modules/q2-predict-dysbiosis/trim_galore.nf'
include { RUN_TRIMGALORE_PAIR } from './modules/q2-predict-dysbiosis/trim_galore.nf'
include { Q2_MANIFEST } from './modules/qiime/q2_manifest.nf'
include { Q2_PREDICT_DYSBIOSIS } from './modules/q2-predict-dysbiosis/q2_predict_dysbiosis.nf'


// Define input parameters
workflow PREPARATION_INPUT {
    take:
        samplesheet

    main:
        // Validate and parse input
        input_res = INPUT_CHECK(samplesheet)

        // Prepare standardized tuple for downstream tools
        prepared_input = input_res.fastq.map { meta, reads -> tuple(meta, reads) }

    emit:
        prepared_input
}


workflow GMWI {
    take:
        prepared_input

    main:
        gmwi_in_single = prepared_input
            .filter { meta, reads -> meta.single_end?.toString() == 'true' }
            .map { meta, reads -> 
                def prefix = meta.run_accession ? "${meta.sample}_${meta.run_accession}" : meta.sample
                tuple(prefix, reads[0], file(params.database_location))
            }

        gmwi_in_pair = prepared_input
            .filter { meta, reads -> !(meta.single_end?.toString() == 'true') }
            .map { meta, reads -> 
                def prefix = meta.run_accession ? "${meta.sample}_${meta.run_accession}" : meta.sample
                tuple(prefix, reads[0], reads[1], file(params.database_location))
            }

        gmwi_res_single = RUN_GMWI2_SINGLE(gmwi_in_single)
        gmwi_res_pair   = RUN_GMWI2_PAIR(gmwi_in_pair)

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

workflow RUN_TRIMGALORE {
    take:
        input_data

    main:
        // 1. Detect SE/PE input
        single_end_data = input_data
            .filter { prefix, reads -> reads.size() == 1 }
            .map { prefix, reads -> tuple(prefix, reads[0]) }

        paired_end_data = input_data
            .filter { prefix, reads -> reads.size() == 2 }
            .map { prefix, reads -> tuple(prefix, reads[0], reads[1]) }

        // 2. Run TrimGalore accordingly
        se_results = RUN_TRIMGALORE_SINGLE(single_end_data)
        pe_results = RUN_TRIMGALORE_PAIR(paired_end_data)

        // 3. Merge SE and PE output
        all_results = se_results.mix(pe_results)

    emit:
        all_results
}


workflow Q2_PREDICT {
    take:
        prepared_input

    main:
        // 1. Format input for TrimGalore
        trim_input = prepared_input.map { meta, reads ->
            def prefix = meta.run_accession ? "${meta.sample}_${meta.run_accession}" : meta.sample
            tuple(prefix, reads)
        }

        trimmed_reads = RUN_TRIMGALORE(trim_input)

        metaphlan_input = trimmed_reads.map { tuple_data ->
            def prefix = tuple_data[0]
            def read1 = tuple_data[1]
            def read2 = (tuple_data.size() == 3) ? tuple_data[2] : file('/dev/null')
            tuple(prefix, read1, read2, file(params.metaphlan_db))
        }

        metaphlan_channel = RUN_METAPHLAN(metaphlan_input).metaphlan_profile
            .map { path -> 
                def prefix = path.getName().replaceFirst(/_metaphlan\.txt$/, '')
                tuple(prefix, path)
            }

        humann_input = metaphlan_channel
            .join(trimmed_reads, by: 0)
            .map { joined ->
            def prefix = joined[0]
            def metaphlan_profile = joined[1]
            def read1 = joined[2]
            def read2 = (joined.size() == 4) ? joined[3] : file('/dev/null')
            tuple(prefix, read1, read2, metaphlan_profile, file(params.database_location))
            }

        humann_result = RUN_HUMANN(humann_input)
  

    emit:
        humann_genefamilies  = humann_result.genefamilies
        humann_pathabundance = humann_result.pathabundance
        humann_pathcoverage  = humann_result.pathcoverage
        trimmed_reads        = trimmed_reads
        metaphlan            = metaphlan_channel.map { it[1] }
}


workflow QIIME_METAPHLAN {
    take:
        metaphlan

    main:
        qiime_profiles       = Channel.empty()
        qiime_taxonomy       = Channel.empty()
        ch_output_file_paths = Channel.empty()
        ch_warning_message   = Channel.empty()

        // Turn the Path-only channel into (prefix, file) tuples:
        def metaphlan_tuples = metaphlan.map { file ->
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

        // CREATE taxonomy_table here
        taxonomy_table = QIIME_DATAMERGE.out.species_relative_abundance
            .map { file -> 
                def prefix = file.getName().replaceFirst(/_species_relative_abundance\.tsv$/, '')
                tuple(prefix, file)
            }

    emit:
        qiime_profiles
        qiime_taxonomy
        ch_output_file_paths
        ch_warning_message
        taxonomy_table
}

// In your main.nf, update the Q2_PREP workflow:

workflow Q2_PREP {
    take:
        humann_genefamilies
        humann_pathabundance
        humann_pathcoverage
        ch_output_file_paths
        taxonomy_table

    main:
        // Collect all files
        genefamilies_list  = humann_genefamilies.collect()
        pathabundance_list = humann_pathabundance.collect()
        pathcoverage_list  = humann_pathcoverage.collect()

        // Create manifest and get stratified/unstratified tables
        Q2_MANIFEST(genefamilies_list, pathabundance_list, pathcoverage_list)
        
        // Combine taxonomy_table with manifest outputs properly
        dysbiosis_input = taxonomy_table
            .combine(Q2_MANIFEST.out.stratified_table)
            .combine(Q2_MANIFEST.out.unstratified_table)
            .map { sample, species_file, stratified_table, unstratified_table ->
                def meta = [id: sample]
                tuple(meta, species_file, stratified_table, unstratified_table)
            }
        
        // Set mode (can be 'full', 'fast', etc.)
        mode = params.dysbiosis_mode ?: 'full'
        
        // Run Q2 Predict Dysbiosis, passing the model file as an extra input
        model_file_ch = Channel.value(file(params.dysbiosis_model))
        Q2_PREDICT_DYSBIOSIS(dysbiosis_input, mode, model_file_ch)

    emit:
        stratified_table   = Q2_MANIFEST.out.stratified_table
        unstratified_table = Q2_MANIFEST.out.unstratified_table
        dysbiosis_results  = Q2_PREDICT_DYSBIOSIS.out.results
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
    PREPARATION_INPUT(raw_sheet)

    if (params.tool == 'gmwi2') {
        GMWI(PREPARATION_INPUT.out.prepared_input)
        QIIME_METAPHLAN(
            GMWI.out.metaphlan
        )
        FINAL_REPORT(
            GMWI.out.gmwi2_scores,
            GMWI.out.gmwi2_taxa,
            GMWI.out.metaphlan
        )
    }
    else if (params.tool == 'q2-predict') {
        Q2_PREDICT(PREPARATION_INPUT.out.prepared_input)
        QIIME_METAPHLAN(Q2_PREDICT.out.metaphlan)
        Q2_PREP(
            Q2_PREDICT.out.humann_genefamilies,
            Q2_PREDICT.out.humann_pathabundance,
            Q2_PREDICT.out.humann_pathcoverage,
            QIIME_METAPHLAN.out.ch_output_file_paths,
            QIIME_METAPHLAN.out.taxonomy_table
        )
    }
    else {
        exit 1, "ERROR: Invalid value for --tool. Choose 'gmwi2' or 'q2-predict'"
    }
}


