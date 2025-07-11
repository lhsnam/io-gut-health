process QIIME_IMPORT {
    tag { prefix }
    
    container 'quay.io/qiime2/core:2023.9'
    
    input:
    tuple val(prefix), path(rel_profile)

    output:
    path '*relfreq_table.qza' , emit: relabun_qza
    
    script:
    """
    qiime tools import --input-path $rel_profile --type 'FeatureTable[Frequency]' --input-format BIOMV100Format --output-path ${prefix}_qiime_relfreq_table.qza
    """
}
