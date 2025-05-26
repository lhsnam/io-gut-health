process METAPHLAN_QIIMEPREP {
    tag { prefix }
    container 'quay.io/biocontainers/biom-format:2.1.15'
    
    input:
    tuple val(prefix), path(mpa_profile)

    output:
    tuple val(prefix), path('*relabun_parsed_mpaprofile.biom') , emit: mpa_biomprofile
    path('*profile_taxonomy.txt') , emit: taxonomy

    script:
    """
    head -n 4 $mpa_profile > ${prefix}_infotext.txt
    sed '1,3d' $mpa_profile | sed 's/#//g' > ${prefix}_profile.txt
    metaphlan_parse_abun.py -t ${prefix}_profile.txt --label "${prefix}"
    biom convert -i ${prefix}_relabun_parsed_mpaprofile.txt -o ${prefix}_relabun_parsed_mpaprofile.biom --table-type="OTU table" --to-json
    """
}
