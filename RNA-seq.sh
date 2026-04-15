# Create main project folder
mkdir RNA_seq

# Move into that folder
cd RNA_seq/

# Create subdirectories each dedicated to a specific stage of the workflow
mkdir bioinformatics_tools
mkdir raw_data
mkdir trimming_data
mkdir Genome
mkdir alignment_hisat2
mkdir quantification_featureCounts

# Download FASTQ files from SRA

# Move into raw_data directory
cd raw_data

# Download reads with fastq-dump

# -X 1000000 tells it to stop after 1 million spots
# --split-3 is safer for paired-end data
# --gzip compresses it on the fly
$ fastq-dump --split-3 --gzip -X 1000000 SRR11772358

# Save output to a log file

# 2>&1: This captures both "standard output" and "errors" so you don't miss anything.
# | tee my_download_log.txt: This saves everything to that file while letting you watch the progress.
$ fastq-dump --split-3 --gzip -X 1000000 SRR11772358 2>&1 | tee my_download_log.txt

# Run FastQC on raw reads
fastqc *.gz

# Trim and clean reads with fastp

# -i / -I: Input files (Read 1 and Read 2).
# -o / -O: Output files.
# --html: Creates a visual web report to show before-and-after quality statistics.
# --trim_front1 12 / --trim_front2 12: Cuts the first 12 bases off the start of every read (removes adapter "artifacts" or sequence bias).
# --trim_tail1 5 / --trim_tail2 5: Cuts the last 5 bases off the end of every read where quality is usually lowest.
# --cut_right: Uses a sliding window to scan the read; it cuts off the tail as soon as it hits a low-quality patch.
# --length_required 30: Discards any read that ends up shorter than 30 bases after trimming (shorter reads are too hard to map accurately).
fastp -i /user/work/iy21106/RNA_seq/raw_data/SRR11772358_1.fastq.gz -I /user/work/iy21106/RNA_seq/raw_data/SRR11772358_2.fastq.gz -o R1.fastq.gz -O R2.fastq.gz  --html fastp_report.html  --trim_front1 12 --trim_front2 12 --trim_tail1 5 --trim_tail2 5 --cut_right  --length_required 30

# Download and decompress human genome from Ensembl

# Move into Genome directory
cd /user/work/iy21106/RNA_seq/Genome

# Download genome using wget
wget https://ftp.ensembl.org/pub/release-115/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz

# Decompress genome file
gunzip Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz

# Build HISAT2 genome index

# Create directory for index files
mkdir index_hisat2

# Run hisat2-build to generate index
hisat2-build Homo_sapiens.GRCh38.dna.primary_assembly.fa /user/work/iy21106/RNA_seq/Genome/index_hisat2/Homo_sapiens.GRCh38.dna.primary_assembly.fa

# Align reads to reference genome using HISAT2

# Move into HISAT alignment directory
cd /user/work/iy21106/RNA_seq/alignment_hisat2

# Run HISAT2 to align paired-end reads

# -x: The path and base name of your index
# -1 and -2: Your cleaned paired-end reads
# -S: The name of the output SAM file
# --summary-file: Detailed alignment stats
$ hisat2 -x /user/work/iy21106/RNA_seq/Genome/index_hisat2/Homo_sapiens.GRCh38.dna.primary_assembly.fa -1 /user/work/iy21106/RNA_seq/trimming_data/R1.fastq.gz -2 /user/work/iy21106/RNA_seq/trimming_data/R2.fastq.gz -S SRR11772358.sam --summary-file mapping_summary.txt

# Convert SAM to sorted BAM using Samtools
samtools sort SRR11772358.sam -o SRR11772358_sorted.bam

# Download Gene Annotation File (GTF)

# Move into Genome directory
cd /user/work/iy21106/RNA_seq/Genome/

# Download Ensembl GTF file using wget
wget https://ftp.ensembl.org/pub/release-115/gtf/homo_sapiens/Homo_sapiens.GRCh38.115.gtf.gz

# Decompress the annotation file
gunzip Homo_sapiens.GRCh38.115.gtf.gz

# Quantify reads with featureCounts

# Move to Quantification directory
cd quantification_featureCounts

# Run featureCounts

# -p: Data is paired-end
# -t exon: Count reads overlapping exons
# -g gene_id: Group exons by gene ID (to get gene-level counts)
# -a: The annotation file (GTF)
# -o: The output file name
featureCounts -t exon -g gene_id -a /user/work/iy21106/RNA_seq/Genome/Homo_sapiens.GRCh38.115.gtf -o gene_counts.txt /user/work/iy21106/RNA_seq/alignment_hisat2/SRR11772358.bam

# Clean count file for DESeq2

# grep -v "^#": removes the first line which starts with # (the command log)
# -f1,7: keeps the 1st and 7th columns
$ grep -v "^#" gene_counts.txt | cut -f1,7 > count.txt

# Create directories for transcriptome reconstruction workflow
cd /user/work/iy21106/RNA_seq/

# Create subdirectories for each step
mkdir stringtie
mkdir Transdecoder
mkdir kallisto

# Transcript assembly with StringTie

# Move into stringtie directory
cd stringtie/

# Run StringTie on sorted BAM file

# -o: output GTF file, -G: reference annotation (optional but helpful)
$ stringtie /user/work/iy21106/RNA_seq/alignment_hisat2/SRR11772358_sorted.bam -o assembly.gtf

# Extract transcript FASTA sequences with gffread

# -w: output fasta of spliced exons (transcripts)
# -g: the genomic fasta file
$ gffread assembly.gtf -g /user/work/iy21106/RNA_seq/Genome/Homo_sapiens.GRCh38.dna.primary_assembly.fa -w transcripts.fasta


# Identify coding regions with TransDecoder

# Move into TransDecoder directory
cd /user/work/iy21106/RNA_seq/Transdecoder/

# Run TransDecoder.LongOrfs to detect long ORFs

# Find all ORFs at least 100 amino acids long
$ TransDecoder.LongOrfs -t /user/work/iy21106/RNA_seq/stringtie/transcripts.fasta -O TransDecoder_LongOrfs]

# Run predict step

# The next step (Predict) uses a statistical model to decide which ones are likely real.
$ TransDecoder.Predict -t /user/work/iy21106/RNA_seq/stringtie/transcripts.fasta -O TransDecoder_LongOrfs

# Transcript-level quantification using Kallisto

# Build Kallisto index
cd /user/work/iy21106/RNA_seq/kallisto/

# Create the kallisto index from your TransDecoder CDS
# -i specifies the name of the index file you want to create
$ kallisto index -i /user/work/iy21106/RNA_seq/kallisto/transdecoder_index.idx /user/work/iy21106/RNA_seq/Transdecoder/TransDecoder_LongOrfs/transcripts.fasta.transdecoder.cds

# Quantify transcripts using Kallisto

# -i: index, -o: output folder
$ kallisto quant -i transdecoder_index.idx -o output_folder /user/work/iy21106/RNA_seq/trimming_data/R1.fastq.gz /user/work/iy21106/RNA_seq/trimming_data/R2.fastq.gz



