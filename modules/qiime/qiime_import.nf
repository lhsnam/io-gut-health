process QIIME_IMPORT {
    tag { prefix }
    
    container 'quay.io/qiime2/core:2023.9'
    
    input:
    tuple val(prefix), path(abs_profile)

    output:
    path '*absfreq_table.qza' , emit: absabun_qza
    
    script:
    """
    qiime tools import --input-path $abs_profile --type 'FeatureTable[Frequency]' --input-format BIOMV100Format --output-path ${prefix}_qiime_absfreq_table.qza
    """
}
