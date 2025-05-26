process MERGE_MARKER_MAP {
    tag "MERGE_MARKER_MAP"
    publishDir "${params.outdir}", mode: 'copy', overwrite: true

    input:
    val stats_files

    output:
    path 'all_marker_map.tsv'

    script:
    // remove any duplicate paths
    def uniqueFiles = stats_files.unique()
    // build a space-separated list for the shell
    def fileList    = uniqueFiles.join(' ')
    def first       = uniqueFiles[0]

    """
    # grab the header from the very first file only
    head -n1 ${first} > all_marker_map.tsv

    # for each unique file, skip its header and append its body
    for f in ${fileList}; do
      tail -n +2 "\$f" >> all_marker_map.tsv
    done
    # after the for‐loop
    sort all_marker_map.tsv | uniq > tmp.tsv && mv tmp.tsv all_marker_map.tsv
    """
}
