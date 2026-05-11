# code to replace gene IDs with gene names in H-MAGMA genes.annot files

import requests, io, gzip
from gtfparse import read_gtf
import polars as pl

# download and parse GENCODE v49 GTF for GRCh37
url = 'https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_49/GRCh37_mapping/gencode.v49lift37.basic.annotation.gtf.gz'
response = requests.get(url,stream=True)
data = gzip.decompress(response.content)
data = io.StringIO(data.decode('utf-8'))
df = read_gtf(data)

type(df) # polars data frame
df.shape # (5860332, 33)
df.columns # column names

# subset to protein-coding genes on chr1-22,X,Y
geneDf = df.filter(
	(pl.col('feature')=='gene') & 
	(pl.col('gene_type')=='protein_coding') &
	(pl.col('seqname')!='chrM'))
geneDf = geneDf.select('seqname','start','end','gene_id','gene_name')
geneDf.shape # (20209, 5)

# inspect entries with duplciated gene names
with pl.Config(tbl_rows=-1): # print all rows
	print(geneDf.filter(geneDf.select('gene_name').is_duplicated()).sort('gene_name'))
# 19 duplicated genes on X vs. Y chromosome (X entry comes before Y entry)
# 10 other duplicated genes with similar coordinates on same chromosome

# remove duplicated gene names by keeping first entry only
geneDf = geneDf.unique(subset='gene_name',keep='first')
geneDf.shape # (20180, 5)

# strip suffix from gene_id (split into 2 columns)
geneDf = geneDf.with_columns(
	pl.col('gene_id')
	.str.split_exact('.',1)
	.struct.rename_fields(['gene_id','gene_id_suffix'])
).unnest('gene_id')

# confirm again gene_id and gene_name are both unique
geneDf.select('gene_id').unique().shape # (20180, 1)
geneDf.select('gene_name').unique().shape # (20180, 1)

# chromosomal position column: CHR:START:END
#geneDf = geneDf.with_columns(
#	pl.col('seqname').cast(pl.String).str.strip_prefix('chr')
#).with_columns(
#	chr_pos = pl.concat_str(['seqname','start','end'],separator=':')
#)

# dictionary of gene_id to gene_name
idDict = dict(geneDf.select('gene_id','gene_name').iter_rows())

# dictionary of gene_id to chromosomal position
#posDict = dict(geneDf.select('gene_id','chr_pos').iter_rows())


# dictionary of name to url of H-MAGMA genes.annot files
# https://github.com/thewonlab/H-MAGMA
annotDict = {'Fetal-Brain':'https://raw.githubusercontent.com/thewonlab/H-MAGMA/refs/heads/master/Input_Files/Fetal_brain.genes.annot',
	'Adult-Brain':'https://raw.githubusercontent.com/thewonlab/H-MAGMA/refs/heads/master/Input_Files/Adult_brain.genes.annot',
	'iPSC-Neuron':'https://raw.githubusercontent.com/thewonlab/H-MAGMA/refs/heads/master/Input_Files/%20iPSC_derived_neuro.genes.annot',
	'iPSC-Astrocyte':'https://raw.githubusercontent.com/thewonlab/H-MAGMA/refs/heads/master/Input_Files/iPSC_derived_astro.genes.annot',
	'Cortical-Neuron':'https://raw.githubusercontent.com/thewonlab/H-MAGMA/refs/heads/master/Input_Files/Cortical_Neuron.genes.annot',
	'Midbrain-DA-Neuron':'https://raw.githubusercontent.com/thewonlab/H-MAGMA/refs/heads/master/Input_Files/Midbrain_DA.genes.annot'}
# References (PMID)
# Fetal-Brain: 27760116, Adult-Brain: 30545857, iPSC-Neuron and Astrocyte: 30545851
# Cortical-Neuron: 34172755, Midbrain-DA-Neuron: 35422469


# iterate through each genes.annot file
for annot in annotDict:
	input = requests.get(annotDict[annot],stream=True)
	outPath = '../data/260511_H-MAGMA_' + annot + '.genes.annot'
	with open(outPath,'w') as outFile:
		for line in input.iter_lines(decode_unicode=True):
			fields = line.strip().split('\t')
			# if gene ID found in GENCODE idDict,
			# replace with gene name and write line to output file
			if fields[0] in idDict:
				# skip chr position check (H-MAGMA used GENCCODE v26, similar but not identical to v49 data)
				#if posDict[fields[0]] == fields[1]:
				fields[0] = idDict[fields[0]]
				outFile.write('\t'.join(fields) + '\n')

