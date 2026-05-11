version 1.0

workflow main {
	input {
		# docker image with MAGMA and gcloud CLI
		String magma_docker = "us-central1-docker.pkg.dev/lage-genoppi/genoppi/magma:2026.05.11"
		
		# bucket to store output
		String destination
		
		# input to MAGMA
		String? window_size = "50" # can have two numbers ('X,Y') for asymmetrical window
		File? snp_filter_file
		File snp_loc_file
		File gene_loc_file
		String output_prefix
	}
	
	call run_magma_annotate {
		input:
			magma_docker = magma_docker,
			destination = destination,
			window_size = window_size,
			snp_filter_file = snp_filter_file,
			snp_loc_file = snp_loc_file,
			gene_loc_file = gene_loc_file,
			output_prefix = output_prefix
	}

	output {
		# bucket link to output file
		String out_annot_link = run_magma_annotate.out_annot_link
	}
}

task run_magma_annotate {
	input {
		String magma_docker
		String destination
		String? window_size
		File? snp_filter_file
		File snp_loc_file
		File gene_loc_file
		String output_prefix
	}
	
	command <<<
		echo "### run MAGMA annotation step"
		magma --annotate \
		~{if defined(window_size) then "window=" + window_size else ""} \
		~{if defined(snp_filter_file) then "filter=" + snp_filter_file else ""} \
		--snp-loc "~{snp_loc_file}" \
		--gene-loc "~{gene_loc_file}" \
		--out "~{output_prefix}"
		
		echo "### upload output genes.annot file to destination bucket"
		outLink="~{destination}/~{output_prefix}.genes.annot"
		gcloud storage cp "~{output_prefix}.genes.annot" "${outLink}"
		
		echo "${outLink}" > out.txt
	>>>
	
	output {
		String out_annot_link = read_string("out.txt")
	}
	
	runtime {
		docker: "~{magma_docker}"
		memory: "4 GB"
		cpu: 1
		preemptible: 1
	}
}

