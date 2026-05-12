version 1.0

workflow main {
	input {
		# docker image with MAGMA and gcloud CLI
		String magma_docker = "us-central1-docker.pkg.dev/lage-genoppi/genoppi/magma:2026.05.11"

		# bucket to store output
		String destination

		# input to MAGMA
		String annot
		String trait
		File gene_file
		String background
		File? background_file
		String set
		File set_file
		String output_prefix
	}

	call run_magma_set {
		input:
			magma_docker = magma_docker,
			destination = destination,
			annot = annot,
			trait = trait,
			gene_file = gene_file,
			background = background,
			background_file = background_file,
			set = set,
			set_file = set_file,
			output_prefix = output_prefix
	}

	output {
		# bucket with output files
		String gsa_out_link = run_magma_set.gsa_out_link
		String log_link = run_magma_set.log_link
	}
}

task run_magma_set {
	input {
		String magma_docker
		String destination
		String annot
		String trait
		File gene_file
		String background
		File? background_file
		String set
		File set_file
		String output_prefix
	}

	command <<<
		echo "### run MAGMA gene set analysis step"
		magma --gene-results "~{gene_file}" \
		--set-annot "~{set_file}" \
		~{if defined(background_file) && background_file != "" then "--settings gene-include=" + background_file else ""} \
		--out "~{output_prefix}.~{annot}.~{trait}.~{background}.~{set}"
	
		echo "### list and upload output files to destination bucket"
		# must have: gsa.out, log; optional (for sets with P < 0.05): gsa.genes.out, gsa.sets.genes.out
		ls "~{output_prefix}.~{annot}.~{trait}.~{background}.~{set}.*"
		gcloud storage cp "~{output_prefix}.~{annot}.~{trait}.~{background}.~{set}.*" "~{destination}"

		echo "### save output links to gsa.out and log files"
		echo "~{destination}/~{output_prefix}.~{annot}.~{trait}.~{background}.~{set}.gsa.out" > outLink.txt
		echo "~{destination}/~{output_prefix}.~{annot}.~{trait}.~{background}.~{set}.log" > logLink.txt
	>>>

	output {
		String gsa_out_link = read_string("outLink.txt")
		String log_link = read_string("logLink.txt")
	}

	runtime {
		docker: "~{magma_docker}"
		memory: "2 GB"
		cpu: 1
		preemptible: 1
	}	
}

