FROM continuumio/miniconda3:latest

RUN apt-get update && \
    apt-get install -y procps g++ bwa samtools && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/analysis

COPY environment.yml .

RUN conda install -y -c conda-forge mamba && \
    mamba env create -f environment.yml && \
    mamba clean -afy

SHELL ["conda", "run", "-n", "io-gmwi2-pipeline", "/bin/bash", "-c"]

ENV PATH=/opt/conda/envs/io-gmwi2-pipeline/bin:$PATH

CMD ["bash"]
