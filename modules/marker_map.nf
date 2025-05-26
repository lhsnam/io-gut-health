process MARKER_MAP {
    tag { sample_id }

    publishDir "${params.outdir}/marker_map", mode: 'copy', overwrite: true

    input:
      tuple val(sample_id), path(mpa_txt), path(coef_txt), path(marker_db)

    output:
      path "${sample_id}_marker_map.tsv"

    script:
    """
    marker_map.py \
      --mpa   ${mpa_txt} \
      --coef  ${coef_txt} \
      --db    ${marker_db} \
      --sample ${sample_id} \
      --output ${sample_id}_marker_map.tsv
    """
}
