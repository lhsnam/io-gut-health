#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process RUN_GMWI2 {
  tag { "${sample}_${run}" }

  input:
    tuple val(sample), path(read1), path(read2), val(group), val(run)

  output:
    path "${sample}_${run}_GMWI2.txt", emit: gmwi2_score
    path "${sample}_${run}_GMWI2_taxa.txt", emit: gmwi2_taxa
    path "${sample}_${run}_metaphlan.txt", emit: metaphlan

  // adjust threads via params.threads or default to 8
  cpus params.threads ?: 8

  script:
  """
  gmwi2 -f ${read1} -r ${read2} -n ${task.cpus} -o ${sample}_${run}
  """
}
