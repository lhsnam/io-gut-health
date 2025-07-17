process METAPHLAN_QIIMEPREP {
    tag { prefix }
    container 'quay.io/biocontainers/biom-format:2.1.15'

    publishDir "${params.outdir}/metaphlan_profiles", mode: 'copy', overwrite: true, pattern: "${prefix}_profile.txt"
    
    input:
    tuple val(prefix), path(mpa_profile)

    output:
    tuple val(prefix), path('*relabun_parsed_mpaprofile.biom') , emit: mpa_biomprofile
    path('*profile_taxonomy.txt') , emit: taxonomy
    path('*_profile.txt') , emit: profile

    script:
    """
    head -n 5 $mpa_profile > ${prefix}_infotext.txt
    sed '1,4d' $mpa_profile | sed 's/#//g' > ${prefix}_profile.txt
    metaphlan_parse_abun.py -t ${prefix}_profile.txt --label "${prefix}"
    biom convert -i ${prefix}_relabun_parsed_mpaprofile.txt -o ${prefix}_relabun_parsed_mpaprofile.biom --table-type="OTU table" --to-json
    """
}
