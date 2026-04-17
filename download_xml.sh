#!/bin/bash

# Define first argument as ACCESSION
ACCESSION=$1

# Download run xml
curl -X 'GET' \
  "https://www.ebi.ac.uk/ena/submit/webin-v2/run/${ACCESSION}" \
  -H 'accept: application/xml' \
  -H 'Authorization: Basic <insert 36 character authorization code>' \
  > ${ACCESSION}.xml
