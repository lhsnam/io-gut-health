process MERGE_MARKER_MAP {
    tag "MERGE_MARKER_MAP"
    publishDir "${params.outdir}", mode: 'copy', overwrite: true

    input:
    val stats_files

    output:
    path 'all_marker_map.tsv'

    script:
    script:
    /*
     * Build a Groovy list → space-separated shell list,
     * and also pull off the “first” for the header.
     */
    def fileList = stats_files.collect { it.getName() }.join(' ')
    def first    = stats_files[0].getName()

    """
    # 1) Grab the header from the first file
    head -n1 ${first} > all_marker_map.tsv

    # 2) For each file, skip its header and append its body
    for f in ${fileList}; do
      tail -n +2 \"\$f\" >> all_marker_map.tsv
    done
    """
}
