#########################
## Building Gene Trees ##                      
#########################

# Format FASTA sequence headers for labelling in phylogenetic tree
sed "s/>\(.*\[\)\([[:alpha:]].*\]\)/>\2 \1/g" < opsins.fa | tr "[" " " | tr "]" " " | tr -d ":" | sed "s/  / /g" | tr -d ";" | tr "=" " " | tr "|" " " | tr "." " " | tr "-" " " | sed "s/ $//g" |  tr " " "_" > opsin_reformatted.fa 

# Align the sequences with MAFFT using the linsi algorithm
linsi opsin_reformatted.fa > opsins.aln 

# Build opsin phylogeny using IQTREE, Ultrafast Bootstrap at 1000 replicates
iqtree3 -m MFP -s opsins.aln -bb 1000

# Visualise steps in this analysis by inspecting the content of opsins.al.iqtree
cat opsins.aln.treefile

############################
## Building Species Trees ##
############################

# Untar and unzip the archive containing the file for the practical
tar -xvf 7_genes.tar.gz

# Navigate to Aldolase directory
cd ~/Downloads/7_genes/Aldolase/

# Count number of sequences in the ald.fas file
grep -c ">" ald.fas

# Align the sequences with MAFFT using the linsi algorithm
linsi ald.fas > ald.aln

# Build phylogeny using IQTREE, Ultrafast Bootstrap at 1000 replicates
iqtree3 -m MFP -s ald.aln -bb 1000

# Build phylogenetic trees for 7 genes
# Navigate to genes directory
cd ~/Downloads/7_genes/genes/

# Use for loops to automate the analysis of the 7 genes
for i in *fas
    do
    linsi $i > $i.aln
done

for i in *aln
    do 
    iqtree3 -m MFP -s $i -bb 1000
done

for i in *treefile
    do
    cat $i >> 7trees.tree
done
