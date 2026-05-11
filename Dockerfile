### Dockerfile for MAGMA and gcloud CLI

# Ubuntu base image: https://hub.docker.com/_/ubuntu
FROM ubuntu:22.04
LABEL maintainer="Yu-Han Hsu <yuhanhsu@broadinstitute.org>"

# prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# install dependencies and gcloud CLI
RUN apt-get update && apt-get install -y \
	curl \
	ca-certificates \
	gnupg \
	wget \
	unzip \
	&& echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
	&& curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
	&& apt-get update && apt-get install -y google-cloud-cli \
	&& rm -rf /root/.cache/pip/ \
	&& find /usr/lib/google-cloud-sdk -name "*.pyc" -delete \
	&& find /usr/lib/google-cloud-sdk -name "*__pycache__*" -delete \
	&& rm -rf /var/lib/apt/lists/*

# set working directory
WORKDIR /app

# download and extract MAGMA binary (v1.10, Linux binary with static linking)
RUN wget -O magma_v1.10_static.zip \
	"https://vu.data.surf.nl/public.php/dav/files/lxDgt2dNdNr6DYt/?accept=zip" \
	&& unzip magma_v1.10_static.zip \
	&& rm magma_v1.10_static.zip \
	&& chmod +x magma

# add /app to system PATH (so can run magma from anywhere)
ENV PATH="/app:${PATH}"

