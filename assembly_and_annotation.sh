#####################
## Genome Assembly ##
#####################

# Navigate to directory for practical
cd ~/Downloads/

# Unzip file for practical
unzip Data.zip

# Navigate into Data
cd Data/

# Use FastQC to evaluate the quality of the sequence data
fastqc virus_all_R1.fastq virus_all_R2.fastq

# Use Trimmomatic to delet any low-quality bases from the read data
trimmomatic PE virus_all_R1.fastq virus_all_R2.fastq virus_trimmed_1_paired.fastq virus_trimmed_1_unpaired.fastq virus_trimmed_2_paired.fastq virus_trimmed_2_unpaired.fastq LEADING:10 TRAILING:10 SLIDINGWINDOW:4:20 MINLEN:75

# Generate FastQC reports for trimmed data
fastqc virus_trimmed_1_paired.fastq virus_trimmed_2_paired.fastq

# Assemble the reads using MEGAHIT
megahit -1 virus_trimmed_1_paired.fastq -2 virsu_trimmed_2_paired.fastq -o assembly_all_contigs

# Compute basic assembly statistics using QUAST
quast.py assembly_all_contigs/final.contigs.fa

# Use Prokka to call genes and do basic gene annotation
prokka --kingdom Viral ~/Downloads/Data/assembly_all_contigs/final.contigs.fa

#######################
## Genome Annotation ##
#######################

# Perform structural annotation of Nasuia genome using Prokka
prokka --kingdom Bacteria nasuia.fasta

# Use CheckM2 to assess the completeness of the Nasuia assembly and mixed culture assembly from previous practical
checkm2 database --download --path ./checkm2_db --no_write_json_db

checkm2 predict -i environ_assembly.fasta -o environ_checkm2 --database_path checkm2_db/CheckM2_database/uniref100.KO.1.dmnd


