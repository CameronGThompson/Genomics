# Create main project folder
mkdir Transcriptome_Annotation

# Move in that folder and create subdirectories for each stage of the workflow
cd Transcriptome_Annotation/

mkdir Raw_data
mkdir TransDecoder
mkdir UniProtKB_SwissProt
mkdir BlastP
mkdir Pfam
mkdir HmmScan

# Identifying coding regions with TransDecoder

# Move to TransDecoder directory
cd /user/work/iy21106/Transcriptome_Annotation/TransDecoder

# Run TransDecoder.LongestOrfs to detect long ORFs

# -t <string> transcripts.fasta
# -O  <string> path to intended output directory
$ TransDecoder.LongOrfs -t /user/work/iy21106/Transcriptome_Annotation/Raw_data/transcripts.fasta -O TransDecoder_LongOrfs

# BlastP

# Move into BlastP directory
cd /user/work/iy21106/Transcriptome_Annotation/UniProtKB_SwissProt/

# Download database and decompress it
wget https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz

gunzip uniprot_sprot.fasta.gz

# Format database so BLAST can read it

# -in: DB format you are trying to create
# -dbtype: stating whether your fasta file is a nucleotide or protein sequence. Nucleotide: nucl, Protein: prot
$ makeblastdb -in uniprot_sprot.fasta -dbtype prot

# Run BlastP

# -query: sequence file
# -db: database
# -max_target_seqs 1: Only keep the single best hit for each protein
# -outfmt 6: Standard tabular format (Query, Subject, % Identity, Alignment Length, etc.)
# -evalue 1e-5: Filter out hits that could occur by random chance
$ blastp -query /user/work/iy21106/Transcriptome_Annotation/TransDecoder/TransDecoder_LongOrfs/transcripts.fasta.transdecoder_dir/longest_orfs.pep -db /user/work/iy21106/Transcriptome_Annotation/UniProtKB_SwissProt/uniprot_sprot.fasta -out blastp_results.outfmt6 -evalue 1e-5 -max_target_seqs 1 -outfmt 6

# Download and prepare Pfam database

# Move into Pfam directory 
cd /user/work/iy21106/Transcriptome_Annotation/Pfam

# Download Pfam-A database and decompress the file
wget https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz

gunzip Pfam-A.hmm.gz

# "Press" the database
hmmpress Pfam-A.hmm

# Search for protein domains with HMMER

# Move into Pfam directory
cd /user/work/iy21106/Transcriptome_Annotation/HmmScan/

# Run hmmscan

# --domtblout: This flag creates a specialised tabular output file (TrinotatePFAM.out) that is optimised for downstream annotation tools like Trinotate.
# Pfam-A.hmm: This is the "map" of Hidden Markov Models representing thousands of known protein families.
# Longest_orfs.pep: These are the candidate protein sequences derived from your differentially expressed COVID-19 genes.
# hmmscan.log: This redirects the standard terminal output to a log file, which is helpful for troubleshooting if the search fails.
hmmscan --domtblout TrinotatePFAM.out /user/work/iy21106/Transcriptome_Annotation/Pfam/Pfam-A.hmm /user/work/iy21106/Transcriptome_Annotation/TransDecoder/TransDecoder_LongOrfs/transcripts.fasta.transdecoder_dir/longest_orfs.pep > hmmscan.log

# Refine prediction using your homology evidence

# Run TransDecoder.Predict

# -t: transcripts file
# --retain_blastp_hits: blastp output file from previous step above
# --single_best_only: selecting the best orf of the generated transcripts
$ TransDecoder.Predict -t /user/work/iy21106/Transcriptome_Annotation/Raw_data/transcripts.fasta -O TransDecoder_LongOrfs --retain_blastp_hits /user/work/iy21106/Transcriptome_Annotation/BlastP/blastp_results.outfmt6  --retain_pfam_hits /user/work/iy21106/Transcriptome_Annotation/HmmScan/TrinotatePFAM.out  --single_best_only


