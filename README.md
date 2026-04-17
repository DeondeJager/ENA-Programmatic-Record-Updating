# Programmatically update records on the ENA
*Last updated: 17 April 2026*

I wrote this guide, mostly for my own records, as I spent a couple of days trying to figure out how to programmatically update >200 run and experiment records on the European Nucleotide Archive (ENA) and didn't want to go through that pain again if I ever needed to something similar in the future. 

An update to these records was required, because I had recorded the field `damage treatment` as `complete-removal` (with USER treatment) for ancient DNA libraries and later realised that I had in fact used partial USER treatment ... :eyes: ..., so anyway, I had to change all records to `partial-removal` (see the [MInAS project](https://www.mixs-minas.org/extension-ancient/) for ancient DNA-specific metadata fields).

Not wanting to update 272 run and experiment XML files on [Webin](https://www.ebi.ac.uk/ena/submit/webin/) manually, one-by-one, individually... I decided to look into doing this programmatically, as I had come across this [option](https://ena-docs.readthedocs.io/en/latest/update/metadata/programmatic-read.html) a couple of times in the [ENA docs](https://ena-docs.readthedocs.io/en/latest/submit/general-guide/programmatic.html) but hadn't tried it before.

Turns out it wasn't as easy as I had hoped and I unfortunately found the ENA documentation to be clear as mud for someone with my level of experience (whatever that might be).

So here we are, with a guide that hopefully will help others like me in a similar situation (looking at you, future me).

## 0. Requirements and other use cases
 - This guide assumes you are on a Linux command-line interface and have [curl](https://curl.se/) available.
 - I'm using `XML` files here, but the ENA also supports `JSON` files - just replace the former with the latter in all code and steps below.
 - The example used in this guide is *updating* `RUN` records, but a very similar approach applies to update other [ENA metadata classes](https://ena-docs.readthedocs.io/en/latest/submit/general-guide/metadata.html#metadata-model), such as `EXPERIMENT`, `ANALYSIS`, `SAMPLE`, and `STUDY` records.
 Simply replace `RUN` or `run` in any of the code and steps below with the relevant term, though I haven't actually tested this :open_hands:
 - A similar approach should work for *submitting* new records of any of the ENA metadata model classes, by simply replacing `MODIFY` with `ADD` in `Step 4.1` below.
 But again, I have not tested this, and it means getting all your metadata into `XML` or `JSON` format.
 I assume there are ways to do this from Excel/CSV files, but I haven't looked into this.

## 1. Get list of records
First thing you need is a list of the accessions that you want to edit.

In my case, I wanted to download the metadata `XML`s of all the runs linked to a specific ENA `STUDY`:
 - After logging into Webin, navigated to the "Studies Report" page and clicked on the "Action" icon next to the project (the box with an arrow inside it) and clicking on "Show runs".
 - This brings up a page with all the runs linked to that project, where I clicked on the "Download all results", which downloads a `CSV` file with accession number of the `RUN` in the `id` field, and also includes the `STUDY`, `EXPERIMENT`, and `SAMPLE` accessions. 
 This is useful if you need to update any other metadata, for example I also need to update the `damage treatment` field in the `EXPERIMENT` records too.
 - Here are the first three lines of the `CSV` file, which we view with `head -n 3 runs-2026-04-17T08_56_33.csv`:
```
id,alias,instrumentModel,firstCreated,firstPublic,releaseStatus,submissionAccountId,studyId,experimentId,sampleId
ERR16691227,"ena-RUN-TAB-16-02-2026-15:13:48:379-71381","Illumina NovaSeq 6000",2026-02-16T15:14:00,,PRIVATE,Webin-65097,ERP188825,ERX16082106,ERS28951525
ERR16691226,"ena-RUN-TAB-16-02-2026-15:13:48:379-71379","Illumina NovaSeq 6000",2026-02-16T15:14:00,,PRIVATE,Webin-65097,ERP188825,ERX16082105,ERS28951524
```

## 2. Get example code from ENA Webin REST API
Now that we have a file with the accession numbers, we need to download the actual `XML` files containing the metadata of the records.

This is where `curl` and the Webin REST API mentioned in the ENA docs comes into play.
 - In a browser, head to the [Webin REST V2 Service](https://www.ebi.ac.uk/ena/submit/webin-v2/swagger-ui/index.html#/).
 - This is a crucial step: Click on the "Authorize" button on the top-right of the screen and enter your Webin credentials - the lock icon should change from open to closed.
 - Under the "retrieveAPI" expand the relevant "GET" section, in my case it was the "GET /run/{id}" section.
 - Click on "Try it out" on the right.
 - Before entering the id, change the "Media type" to "application/xml" (or keep it as "application/json" if that's the format you prefer).
 - Enter one of your accessions in the "id" field and click "Execute".
 - Under "Responses" you will see the "Curl" section with the `curl` code, including a 36-character authorization code, you need to download the `XML` for the accession, which we will use in the next section.
  - Copy and paste this code into a text document and save it as `download_xml.sh` or some descriptive name.

## 3. Download XML (or JSON) files

### 3.1. Make download script
Edit the `download_xml.sh` to match the script below, which makes it a `bash` script (`#!/bin/bash`) and replaces the accession used in Step 2 with a variable that is defined as the first input argument of the script (`ACCESSION=$1`).
 - Alternatively, you can skip Step 2 and download the pre-prepared script included in this repo, but note that future changes in the API or curl might break it, in which case repeat Step 2 to ensure you have the correct code.
 - **NB**: Replace "`<insert 36 character authorization code>`" with the code obtained from the API website in Step 2.

*download_xml.sh*:
```
#!/bin/bash

# Define first (and only) argument as ACCESSION
ACCESSION=$1

# Download run xml
curl -X 'GET' \
  "https://www.ebi.ac.uk/ena/submit/webin-v2/run/${ACCESSION}" \
  -H 'accept: application/xml' \
  -H 'Authorization: Basic <insert 36 character authorization code>' \
  > ${ACCESSION}.xml
```
### 3.2. Download the actual `XML` files
Here we use the `CSV` file downloaded in Step 1 and the `download_xml.sh` script to download all the `XML` files.
```
tail -n +2 runs-2026-04-17T08_56_33.csv | cut -f1 -d "," | while read -r line; do ./download_xml.sh $line; done
```
Where:
 - `tail -n +2`: Skips the first line (header) of the downloaded `CSV`,
 - `cut -f1 -d ","`: Selects the first field/column (`-f`) of the `CSV`, as passed from `tail` and defines the field delimiter as a comma (`-d`),
 - `while read -r line; do ./download_xml.sh $line; done`: Loops through the input received from `cut` line by line and passes it to the download script to download the `XML` for each accession in the `CSV`. 

*Note: To download the `STUDY`, `EXPERIMENT`, or `SAMPLE` `XML` files instead, use `-f8`, `-f9`, or `-f10`, respectively.*

### 3.3. Update your `XML` files
Make whatever edits are required.

I had to make the same change to many files, which is where the command-line shines and is why I wanted to go this route.

Here is what I did for my problem described at the beginning:
```
for file in ERR*.xml; do sed -i 's/complete-removal/partial-removal/g' $file; done
```
This replaces all instances of "complete-removal" with "partial-removal" in all the files staring with "ERR" and ending with ".xml" in-place in the file (`-i`), so without opening it.
Beautiful.

## 4. Resubmit the updated `XML` files to the ENA
This is a part I particularly struggled to figure out, as the API page used earlier has a "submitAPI", which I tried and it provided some code, but it kept giving an error about not being able to separate the file.

After some searching online, [SciLifeLab's](https://data-guidelines.scilifelab.se/) [tutorial](https://data-guidelines.scilifelab.se/topics/ena-submission-tutorial/) and [this](https://youtu.be/1qvG9mtxSYo?si=knZWZlOi7EQkH9Ew&t=1126) ENA YouTube video helped clarify the exact command needed for uploading `XML` files via `curl`, which is different to the code provided by the "submitAPI".

### 4.1. Make an action `XML`
First, make an "action" `XML` file, which describes the action you want to perform; e.g. `MODIFY` for editing existing entries, or `ADD` for submitting new entries.
 - Here, we create a the file `modify.xml`, but you can also make a `submit.xml` and replace `MODIFY` with `ADD` for new submissions:

*modify.xml*:
```
<SUBMISSION>
     <ACTIONS>
         <ACTION>
             <MODIFY/>
         </ACTION>
    </ACTIONS>
</SUBMISSION>
```
Then we can upload our modified `RUN` `XML` to update the record. 

We first upload it to the ENA test server, denoted by `wwwdev` in the URL, to make sure our code works (use your own Webin username and password):
```
curl -u username:password -F "RUN=@ERR16691103.xml" -F "SUBMISSION=@modify.xml" "https://wwwdev.ebi.ac.uk/ena/submit/drop-box/submit/"
```
You should get output on screen that looks something like this - look for `success="true"`:
```
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="receipt.xsl"?>
<RECEIPT receiptDate="2026-04-17T20:16:17.446+01:00" submissionFile="modify.xml" success="true">
     <RUN accession="ERR16691103" alias="ena-RUN-TAB-16-02-2026-15:13:48:337-71133" status="PRIVATE"/>
     <SUBMISSION accession="" alias="SUBMISSION-17-04-2026-20:16:17:422"/>
     <MESSAGES>
          <INFO>The XML md5 checksum for the object being updated has not changed. No update required for ERR16691103.</INFO>
          <INFO>This submission is a TEST submission and will be discarded within 24 hours</INFO>
     </MESSAGES>
     <ACTIONS>MODIFY</ACTIONS>
</RECEIPT>
```
**Now we're ready to do the real upload, by removing `dev` from the URL**:
```
curl -u username:password -F "RUN=@ERR16691103.xml" -F "SUBMISSION=@modify.xml" "https://www.ebi.ac.uk/ena/submit/drop-box/submit/"
```
 - Make sure it worked by checking for `success="true"` in the on-screen output and by manually checking the run's `XML` on Webin in a browser to confirm.

For many `XML`s, we can wrap the command in a loop, and we also save the screen output to a file so we have it on record and check everything worked as expected.

In a directory containing all the updated `XML`s you want to upload and the `modify.xml` we created, run:
```
for file in ERR*.xml; do curl -u username:password -F "RUN=@$file" -F "SUBMISSION=@modify.xml" "https://www.ebi.ac.uk/ena/submit/drop-box/submit/" &>> runs_update_receipt.xml; done
```
 - `ERR*.xml` should be changed to match your filenames, for example `ERX*.xml` for `EXPERIMENT` files.
 - `&>> runs_update_receipt.xml` adds and appends the screen output for each `XML` to the file `runs_update_receipt.xml` (`>` = overwrite, `>>` = append).
 - Check the `runs_update_receipt.xml` for `success="true"` (or `success="false"`) to ensure everything went smoothly, and check a couple of files manually on Webin just to make sure.

**And we're done!** 
Celebrate with a :cookie:
