// Process: prepare MetaPhlAn database once before GMWI2 runs
process DATABASE_PREPARATION {
    tag "database_preparation"
    conda 'bioconda::gmwi2=1.6'

    // Dummy input to trigger exactly once
    input:
        val(trigger)

    // No outputs needed; just wait for install to complete
    output:
        val(true), emit: db_ready

    script:
    """
    DB_DIR=`sh -c "find \$CONDA_PREFIX -type d -name metaphlan_databases | head -n1"`
    if [ -z "\$DB_DIR" ]; then
      echo "ERROR: Could not find metaphlan_databases directory in \$CONDA_PREFIX" >&2
      exit 1
    fi

    echo "Syncing mpa_v30_CHOCOPhlAn_201901 database ..."
    cp -r ${params.metaphlan_db}* "\$DB_DIR"
    
    set -euo pipefail

    MD5_FILE=`sh -c "find \$CONDA_PREFIX -type f -name GRCh38_md5sum.txt | head -n1"`
    if [ -z "\$MD5_FILE" ]; then
      echo "ERROR: Could not find GRCh38_md5sum.txt in \$CONDA_PREFIX" >&2
      exit 1
    fi

    DB_DIR=`sh -c "dirname \$MD5_FILE"`

    echo "Syncing human genome folder to the location of MD5 file..."
    cp -r ${params.human_genome} "\$DB_DIR"
    """
}
