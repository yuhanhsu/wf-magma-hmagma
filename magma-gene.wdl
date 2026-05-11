version 1.0

workflow main {
	input {
		# docker image with MAGMA and gcloud CLI
		String magma_docker = "us-central1-docker.pkg.dev/lage-genoppi/genoppi/magma:2026.05.11"

		# bucket to store output
		String destination

		# input to MAGMA
		File ref_zipped_file # zipped folder containing genotype (bed/bim/fam) and SNP synonym files
		String ref_prefix # prefix of bed/bim/fam/synonym file names in ref_zipped_file
		File annot_file
		String trait
		File pval_file
		String? pval_col
		String? snp_col
		String? n_col
		String? N
		String output_prefix
	}

	call run_magma_gene {
		input:
			magma_docker = magma_docker,
			destination = destination,
			ref_zipped_file = ref_zipped_file,
			ref_prefix = ref_prefix,
			annot_file = annot_file,
			trait = trait,
			pval_file = pval_file,
			pval_col = pval_col,
			snp_col = snp_col,
			n_col = n_col,
			N = N,
			output_prefix = output_prefix
	}

	output {
		# bucket links to output
		String genes_out_link = run_magma_gene.genes_out_link
		String genes_raw_link = run_magma_gene.genes_raw_link
		String log_link = run_magma_gene.log_link
	}
}

task run_magma_gene {
	input {
		String magma_docker
		String destination
		File ref_zipped_file
		String ref_prefix
		File annot_file
		String trait
		File pval_file
		String? pval_col
		String? snp_col
		String? n_col
		String? N
		String output_prefix
	}

	command <<<
		echo "### unzip reference data folder"
		unzip "~{ref_zipped_file}" -d refData	

		echo "### run MAGMA gene analysis step"
		magma --bfile refData/"~{ref_prefix}" \
		--gene-annot "~{annot_file}" \
		--pval "~{pval_file}" \
		~{if defined(pval_col) then "pval=" + pval_col else ""} \
		~{if defined(snp_col) then "snp-id=" + snp_col else ""} \
		~{if defined(n_col) then "ncol=" + n_col else ""} \
		~{if defined(N) then "N=" + N else ""} \
		--out "~{output_prefix}.~{trait}" > "~{output_prefix}.~{trait}.log"

		echo "### upload output and log files to destination bucket"
		outLink="~{destination}/~{output_prefix}.~{trait}.genes.out"
		gcloud storage cp "~{output_prefix}.~{trait}.genes.out" "${outLink}"

		rawLink="~{destination}/~{output_prefix}.~{trait}.genes.raw"
		gcloud storage cp "~{output_prefix}.~{trait}.genes.raw" "${rawLink}"
		
		logLink="~{destination}/~{output_prefix}.~{trait}.log"
		gcloud storage cp "~{output_prefix}.~{trait}.log" "${logLink}"

		echo "${outLink}" > outLink.txt
		echo "${rawLink}" > rawLink.txt
		echo "${logLink}" > logLink.txt
	>>>

	output {
		String genes_out_link = read_string("outLink.txt")
		String genes_raw_link = read_string("rawLink.txt")
		String log_link = read_string("logLink.txt")
	}

	runtime {
		docker: "~{magma_docker}"
		memory: "2 GB"
		cpu: 1
		preemptible: 2
	}
}

