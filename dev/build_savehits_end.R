library(ggplot2)
library(dplyr)
library(stringr)
library(data.table)
library(pvclust)
library(vegan)

#t1 = data.table::fread('t1.csv', sep = ',')  #HUGE

#t1.lca = data.table::fread('t1.lca.csv', sep = ',')  #HUGE
t1.lca.files = list.files('out', pattern='t1.lca.coll', full.names = T)
l <- lapply(t1.lca.files, fread, sep=",")
t1.lca <- bind_rows(l)
colnames(t1.lca)[20] = 'samname'


t1.lca.genus = t1.lca %>%
  filter(phylum=='Streptophyta') %>%
  group_by(QueryID, samname) %>%
  dplyr::slice(1) %>%
  group_by(genus, samname) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  filter(!is.na(genus))  

#%>%
# filter(count > 5) 

cast.gen = reshape2::dcast(t1.lca.genus, samname ~ genus)
cast.gen[is.na(cast.gen)] = 0
rownames(cast.gen) = cast.gen[,1]
gen.dist <- vegdist(decostand(cast.gen[,-1], method='log'), diag=T, method='jaccard')
plot(hclust(gen.dist))
gen.pv <- pvclust(t(decostand(cast.gen[,-1], method='log')), 
                  method.hclust="ward", nboot=100, parallel=T)
plot(gen.pv, print.num=F, print.pv = T)


# 
# # cluster on last_common
# t1.lca.lc = t1.lca %>%
#   group_by(QueryID, samname) %>%
#   dplyr::slice(1) %>%
#   group_by(last_common, samname) %>%
#   summarise(count = n()) %>%
#   arrange(desc(count)) %>%
#   filter(!is.na(last_common))  
# 
# #%>%
# # filter(count > 5) 
# 
# cast.lc = reshape2::dcast(t1.lca.genus, samname ~ last_common)
# cast.lc[is.na(cast.lc)] = 0
# rownames(cast.lc) = cast.lc[,1]
# lc.dist <- vegdist(decostand(cast.lc[,-1], method='log'), diag=T, method='ward')
# plot(hclust(lc.dist))
# lc.pv <- pvclust(t(decostand(cast.lc[,-1], method='log')), 
#                   method.hclust="ward", nboot=100, parallel=T)
# plot(lc.pv, print.num=F, print.pv = T)


ggplot(data = t1.lca.genus %>% filter(count>20)) +
  geom_col(aes(x=samname, y = count, fill=genus), position='dodge') +
  scale_y_log10() +
  theme_minimal() +
  theme(legend.position = 'right',
        axis.text.x = element_text(angle=90)) 


# tile plot heatmap


ggplot(data = t1.lca.genus %>% filter(count>2)) +
  geom_tile(aes(x=samname, y = genus, fill=count)) +
  scale_fill_viridis_b() +
  theme_linedraw() +
  theme(legend.position = 'right',
        axis.text.x = element_text(angle=90)) 


## put tile plot alongside dendrogram of kmer clustering





#other ideas

#merge samples + plot
t1.sample.genus = t1.lca %>%
  mutate(sample = str_trunc(samname, 10)) %>%
  group_by(QueryID, samname) %>%
  dplyr::slice(1) %>%
  group_by(genus, sample) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  filter(!is.na(genus))  %>%
  filter(count > 5) 



ggplot(data = t1.sample.genus %>% mutate(total = sum(count))) +
  geom_col(aes(x=sample, y = count, fill=genus), position=position_dodge2(width = 0.9, preserve = "single")) +
  scale_y_log10() +
  theme_minimal() +
  theme(legend.position = 'right',
        axis.text.x = element_text(angle=90)) 


#merge samples + plot
t1.family = t1.lca %>%
  mutate(sample = str_trunc(samname, 13)) %>%
  group_by(QueryID, samname) %>%
  dplyr::slice(1) %>%
  group_by(family, samname) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  filter(!is.na(family))  %>%
  filter(count > 20) 

ggplot(data = t1.family %>% mutate(total = sum(count))) +
  geom_col(aes(x=samname, y = count, fill=family), position=position_dodge2(width = 0.9, preserve = "single")) +
  scale_y_log10() +
  theme_minimal() +
  theme(legend.position = 'right',
        axis.text.x = element_text(angle=90)) 

cast.fam = reshape2::dcast(t1.family, samname ~ family)
cast.fam[is.na(cast.fam)] = 0
rownames(cast.fam) = cast.fam[,1]
fam.dist <- vegdist(decostand(cast.fam[,-1], method='log'), diag=T, method='jaccard')
plot(hclust(fam.dist))
fam.pv <- pvclust(t(decostand(cast.fam[,-1], method='log')), 
                  method.hclust="ward.D2", nboot=100, parallel=T)
plot(fam.pv, print.num=F, print.pv = T)



# add chart to end of dendrogram?
