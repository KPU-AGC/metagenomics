#!/bin/bash
#
# Generate a manifest file that QIIME2 can read for each of the fastq in a given directory.

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

if [ $# -ne 1 ]; then
    err "Usage: $0 <directory>"
    exit 1
fi

FASTQ_DIRECTORY=$(realpath $1)
if [ ! -d ${FASTQ_DIRECTORY} ]; then
    err "Directory does not exist: ${FASTQ_DIRECTORY}"
    exit 1
fi

OUTPUT_FILE=${FASTQ_DIRECTORY}/"fastq.manifest"

echo -e "sample-id\tforward-absolute-filepath\treverse-absolute-filepath" > "${OUTPUT_FILE}"

find "${FASTQ_DIRECTORY}" -name "*.R1.fastq.gz" | sort | while read R1_PATH; do
    BASE_NAME=$(basename "${R1_PATH}" .R1.fastq.gz)
    R2_PATH="${R1_PATH/R1.fastq.gz/R2.fastq.gz}"
    
    if [ -f "$R2_PATH" ]; then
        SAMPLE_ID=$(echo "${BASE_NAME}" | awk -F. '{print $1}')
        
        echo -e "${SAMPLE_ID}\t${R1_PATH}\t$R2_PATH" >> "${OUTPUT_FILE}"
    else
        err "Matching R2 file not found for ${R1_PATH}"
    fi
done
err "Process completed."