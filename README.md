# io-gmwi2-pipeline

**Author:** NamLHS ([*GitHub*](https://github.com/lhsnam), [*Google Scholar*](https://scholar.google.com/citations?user=j6MKfFMAAAAJ&hl=en)) 🦠

A reproducible Nextflow DSL2 pipeline for running GMWI2 on paired-end metagenomic reads. On first run, it automatically downloads the MetaPhlAn marker database and GRCh38/hg38 reference, then processes all samples in parallel with retry logic and sequential execution as needed.

---

## 📋 Prerequisites

* **Java 8+**
* **Nextflow** (v22.10.6 or later)

---

## 🔧 Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/lhsnam/io-gmwi2-pipeline.git
   cd io-gmwi2-pipeline
   ```
2. **Install Nextflow** (if not already):
   ```bash
   curl -s https://get.nextflow.io | bash
   mv nextflow ~/bin
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

Launch the workflow:

```bash
nextflow run main.nf \
  --design design.csv \
  --outdir results/gmwi2 \
  -profile local
```
---

## 📖 References

* [Nextflow Documentation](https://www.nextflow.io/docs/latest)
* [GMWI2 GitHub](https://github.com/SegataLab/gmwi2)
* [MetaPhlAn Documentation](https://github.com/biobakery/MetaPhlAn)
* [**io-gmwi2-pipeline**](https://github.com/lhsnam/io-gmwi2-pipeline)
