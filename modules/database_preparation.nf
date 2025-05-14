process DATABASE_PREPARATION {
    tag "database_preparation"
    conda 'bioconda::gmwi2=1.6'

    input:
      val trigger

    output:
      val true, emit: db_ready
    script:
    workflow.profile.contains('aws') ? 
    // ───────────── AWS variant ─────────────
    """
    # find MetaPhlAn install dir
    DB_DIR=\$(find \$CONDA_PREFIX -type d -name metaphlan_databases | head -n1)
    if [ -z "\$DB_DIR" ]; then
      echo "ERROR: metaphlan_databases not found in \$CONDA_PREFIX" >&2
      exit 1
    fi

    # use aws sync
    aws s3 sync ${params.metaphlan_db} \$DB_DIR

    MD5_FILE=`sh -c "find \$CONDA_PREFIX -type f -name GRCh38_md5sum.txt | head -n1"`
    if [ -z "\$MD5_FILE" ]; then
      echo "ERROR: Could not find GRCh38_md5sum.txt in \$CONDA_PREFIX" >&2
      exit 1
    fi

    DB_DIR=`sh -c "dirname \$MD5_FILE"`

    aws s3 sync ${params.human_genome} \$DB_DIR/GRCh38_noalt_as

    """ 
    : 
    // ───────────── Local copy variant ─────────────
    """
    # find MetaPhlAn install dir
    DB_DIR=\$(find \$CONDA_PREFIX -type d -name metaphlan_databases | head -n1)
    if [ -z "\$DB_DIR" ]; then
      echo "ERROR: metaphlan_databases not found in \$CONDA_PREFIX" >&2
      exit 1
    fi

    # copy from local filesystem
    cp -r ${params.metaphlan_db}* \$DB_DIR

    MD5_FILE=`sh -c "find \$CONDA_PREFIX -type f -name GRCh38_md5sum.txt | head -n1"`
    if [ -z "\$MD5_FILE" ]; then
      echo "ERROR: Could not find GRCh38_md5sum.txt in \$CONDA_PREFIX" >&2
      exit 1
    fi

    DB_DIR=`sh -c "dirname \$MD5_FILE"`
    
    cp -r ${params.human_genome} \$DB_DIR/GRCh38_noalt_as
    """
}
