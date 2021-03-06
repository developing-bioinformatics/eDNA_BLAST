# run core pipeline for eDNA amplicon data at PRJNA605442

library(Biostrings)
library(taxonomizr)
library(ggplot2)
library(ShortRead)
library(dplyr)
library(stringi)
library(forcats)
library(rBLAST)
library(ggsci)

nclus = 32
taxonomizr_path = '/usr/share/data/taxonomizr/'
files_in = 'data_all'
res_out = 'targdb_allout'
source('R/core.R')

download_sra(proj = 'PRJNA605442', dir.out = files_in)

files = list.files(files_in, full.names = TRUE)

if(dir.exists(res_out)){} else {dir.create(res_out)}

for (i in 1:length(files)) {
  
  samname = tools::file_path_sans_ext(basename(files[[i]]))
  
  print(paste("Starting file:", samname, 'round', i, sep = ' '))
  print(date())
  p = proc.time()
  
  #files should be one or more fastq files
  
  #grep amplicon databases in ./blast_db
  if(grepl('control', samname)){
    amplicon = strsplit(samname, "_")[[1]][3]
  } else {
    amplicon = strsplit(samname, '_')[[1]][4]
  }
  if (grepl('psbA', amplicon)) {amplicon='psbA'}
  if (grepl('rbcL', amplicon)) {amplicon='rbcL'}
  
  print(amplicon)
  
  t1.coll = BLAST_pipeline2(
    files[i],
    blast_args =  '-max_target_seqs 10000',
    blast_db = paste('blast_db/', amplicon, '.fasta', sep=''),
    tax_db = taxonomizr_path,
    parallel = T,
    nclus = nclus,
    save.hits = TRUE,
    E.max = 1e-50,
    Perc.Ident.min = 0,
    blast.type = 'blastn'
  ) #filter on E value not Perc.Ident
  
  t1.coll = cbind(t1.coll, rep(samname, nrow(t1.coll)))
  
  if(nrow(t1.coll) == 0){ next }
  
  
  #t1.lca.coll = lca(t1.coll, parallel = T,  nclus = nclus)
 # t1.lca.coll = t1.coll
  
  # plot
  tlca.coll = t1.coll %>%
    group_by(QueryID) %>%
    dplyr::slice(1) %>%
    group_by(last_common) %>%
    summarise(count = n()) %>%
    arrange(desc(count))
  
  tlca.coll = cbind(tlca.coll, rep(samname, nrow(tlca.coll)))
  
  data.table::fwrite(tlca.coll, paste(res_out, '/tlca.coll.', i, '.csv', sep = ''), nThread = 1)
 # data.table::fwrite(t1.lca.coll, paste('targdb_out/t1.lca.coll.', i, '.csv', sep = ''), nThread = 1)
  data.table::fwrite(t1.coll, paste(res_out, '/t1.coll.', i, '.csv', sep = ''), nThread = 1)
  
  xp = proc.time() - p
  print(paste("Last iteration took:", xp[[3]], sep = ' '))
}

