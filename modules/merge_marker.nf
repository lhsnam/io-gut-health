process MERGE_MARKER_MAP {
    tag "Combine Marker Maps"

    container 'docker.io/namlhs/io-gmwi2-pipeline:5.25'
    
    publishDir "${params.outdir}", mode: 'copy', overwrite: true

    input:
    val stats_files

    output:
    path 'all_marker_map.tsv'

    script:
    def uniqueFiles = stats_files.unique()
    def fileList    = uniqueFiles.join(' ')
    def first       = uniqueFiles[0]

  """
  # take header from the first file
  head -n1 ${first} > all_marker_map.tsv

  # concatenate and sort+uniq *only* the data rows
  {
    for f in ${fileList}; do
      tail -n +2 "\$f"
    done
  } | sort | uniq >> all_marker_map.tsv
  """

}
