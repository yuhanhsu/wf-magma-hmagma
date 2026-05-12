# wf-magma-hmagma

Files for running MAGMA or H-MAGMA analysis workflow on Terra
- Dockerfile to containerize MAGMA and install dependencies
- cloudbuild.yaml to build and push docker image to Google Artifact Registry via Cloud Build
- WDL files (magma-annotate.wdl, magma-gene.wdl, magma-geneset.wdl) to define workflow corresponding to each MAGMA analysis step
- .dockstore.yml to sync workflows to Dockstore

Approximate run time
- Cloud Build: a few minutes
- Dockstore: a few minutes
- Terraw workflow (magma-annotate): a few minutes
- Terra workflow (magma-gene): variable, most <1 hour
- Terra workflow (magma-geneset): TODO

