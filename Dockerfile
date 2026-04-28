### Dockerfile for MAGMA or H-MAGMA analysis

# Ubuntu base image: https://hub.docker.com/_/ubuntu
FROM ubuntu:22.04
LABEL maintainer="Yu-Han Hsu <yuhanhsu@broadinstitute.org>"

# prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# install wget and unzip to download and extract MAGMA
RUN apt-get update && apt-get install -y \
	wget \
	unzip \
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

