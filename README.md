# wf-magma-hmagma

Files for running MAGMA or H-MAGMA analysis workflow on Terra
- Dockerfile to containerize MAGMA and install dependencies
- cloudbuild.yaml to build and push docker image to Google Artifact Registry via Cloud Build
- WDL files (magma-annotate.wdl, magma-gene.wdl, magma-geneset.wdl) to define workflows
- .dockstore.yml to sync workflows to Dockstore
