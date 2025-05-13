# GMWI2 Nextflow Pipeline

**Author:** NamLHS ([*GitHub*](https://github.com/lhsnam), [*Google Scholar*](https://scholar.google.com/citations?user=j6MKfFMAAAAJ&hl=en))🦠


A reproducible Nextflow DSL2 pipeline to run GMWI2 on paired‑end metagenomic reads. On first execution it will automatically install the MetaPhlAn marker database and the GRCh38/hg38 reference, then process all samples in parallel with retry logic and sequential execution guaranteed.

---

## 📋 Prerequisites

* **Java 8+**
* **Nextflow** (v22.10.6 or later)
* **Conda** (or Mamba)
* **AWS CLI** (if pulling databases from S3)
* **AWS credentials** or **IAM role** with read-access to:

  * `s3://io-pipeline-references/metaphlan-databases/...`
  * `s3://io-pipeline-references/genome-databases/...`

---

## 🔧 Installation

1. **Clone the repo**

   ```bash
   git clone https://github.com/lhsnam/io-gmwi2-pipeline.git
   cd io-gmwi2-pipeline
   ```
2. **Install Nextflow** (if not already):

   ```bash
   curl -s https://get.nextflow.io | bash
   mv nextflow ~/bin
   ```
3. **Ensure** Conda (or Mamba) and `aws` are available on your `PATH`.

---

## 🛠️ Local Database Setup

* From your project root, run:

```bash
# create folders
mkdir -p databases/metaphlan-databases databases/genome-databases

# build MetaPhlAn DB
metaphlan --install --index mpa_v30_CHOCOPhlAn_201901 \
  --bowtie2db $PWD/databases/metaphlan-databases

# download GRCh38
wget -q -P databases/genome-databases \
  https://genome-idx.s3.amazonaws.com/bt/GRCh38_noalt_as.zip
unzip -q databases/genome-databases/GRCh38_noalt_as.zip -d databases/genome-databases
rm databases/genome-databases/GRCh38_noalt_as.zip
```
* Alternatively, sync the entire S3 bucket:

````bash
aws s3 sync s3://io-pipeline-references ./databases
````

## 📁 Local Profile Configuration

Instead of editing the main config, create `conf/local.config` in your project root:

```groovy
// conf/local.config
params {
  database_location = './databases'
}
```

Ensure your `databases/` folder (created in the Local Database Setup step) lives at the project root, then run the pipeline as usual:
```
databases/
├─ metaphlan-databases/
│  └─ mpa_v30_CHOCOPhlAn_201901/
│     ├─ mpa_v30_CHOCOPhlAn_201901_marker_info.txt.bz2
│     ├─ mpa_v30_CHOCOPhlAn_201901.1.bt2
│     ├─ mpa_v30_CHOCOPhlAn_201901.2.bt2
│     ├─ mpa_v30_CHOCOPhlAn_201901.3.bt2
│     ├─ mpa_v30_CHOCOPhlAn_201901.4.bt2
│     ├─ mpa_v30_CHOCOPhlAn_201901.fna.bz2
│     ├─ mpa_v30_CHOCOPhlAn_201901.md5
│     ├─ mpa_v30_CHOCOPhlAn_201901.pkl
│     ├─ mpa_v30_CHOCOPhlAn_201901.rev.1.bt2
│     ├─ mpa_v30_CHOCOPhlAn_201901.rev.2.bt2
│     └─ mpa_v30_CHOCOPhlAn_201901.tar
└─ genome-databases/
   └─ GRCh38_noalt_as/
      ├─ GRCh38_noalt_as.1.bt2
      ├─ GRCh38_noalt_as.2.bt2
      ├─ GRCh38_noalt_as.3.bt2
      ├─ GRCh38_noalt_as.4.bt2
      ├─ GRCh38_noalt_as.rev.1.bt2
      └─ GRCh38_noalt_as.rev.2.bt2

```

---

## 🚀 Running the Pipeline

Prepare a sample sheet `design.csv` with columns:

```csv
sample,read_1,read_2,group,run_accession
sample1,s1_run1_R1.fastq.gz,s1_run1_R2.fastq.gz,groupA,run1
sample1,s1_run2_R1.fastq.gz,s1_run2_R2.fastq.gz,groupA,run2
sample2,s2_run1_R1.fastq.gz,,groupB,,
sample3,s3_run1_R1.fastq.gz,s3_run1_R2.fastq.gz,groupB,,
```

Launch the full workflow:

```bash
nextflow run main.nf \
  --design design.csv \
  --outdir results/gmwi2 \
  -profile local
```

* The database step runs first.
* `RUN_GMWI2` scatters across all samples.
* Results are copied under `results/gmwi2/score`, `.../taxa_coef`, `.../metaphlan`.

---

## 📖 References

* [Nextflow Documentation](https://www.nextflow.io/docs/latest)
* [GMWI2 GitHub](https://github.com/SegataLab/gmwi2)
* [MetaPhlAn Documentation](https://github.com/biobakery/MetaPhlAn)
* [**io-gmwi2-pipeline** (this pipeline)](https://github.com/lhsnam/io-gmwi2-pipeline)
