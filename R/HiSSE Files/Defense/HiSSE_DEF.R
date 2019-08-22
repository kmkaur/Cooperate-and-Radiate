#SPECIES Combination ANALYSES with HiSSE#

#load packages
require(ape)
require(phytools)
require(geiger)
require(diversitree)
require(phangorn)
require(caper)
require(hisse)

#set working directory
setwd("~/working_folder_name")

#loading the species tree, new tree provided by Matt & Corrie
#tree<-read.nexus(file="New Tree")
tree<-read.newick(file="Newick_Species_Tree")

#clean it up
genus <- sapply(strsplit(as.character(tree$tip.label), '_'), function(x) x[1])
species <- sapply(strsplit(as.character(tree$tip.label), '_'), function(x) x[2])
tree$tip.label<-paste(genus, species, sep = " ")

#import trait data on the species level
taxa <- read.csv("Species_DEF_pruned_data.csv", row.names=1)

#match up data
TreeOnly <- setdiff(tree$tip.label,rownames(taxa))
DataOnly <- setdiff(rownames(taxa), tree$tip.label)


#taxa2 <- as.matrix(taxa)
#taxa3<-taxa2[-match(DataOnly, rownames(taxa2)),]
#taxa3 <- as.data.frame(taxa3)
#this is the new pruned tree
pruned<-drop.tip(tree, TreeOnly)

#####HiSSE#####

#make tree ultrametric
pruned2<-nnls.tree(cophenetic(pruned),pruned,rooted=TRUE)

#convert data to hisse format
combo<-cbind(rownames(taxa2), taxa2[,1])

#here are all the models:
##important notes:
#1) ALWAYS do ParDrop(matrix, c(3,5,8,10)) because these are transitions b/w 0A and OB,
#and they do not make sense
#2) the turnover.anc = c(0A, 1A, 0B, 1B) and eps.anc = c(0A, 1A, 0B, 1B)
#3) sampling fraction is the same for all of them
samp <- c(0.04780, 0.1046)

#####1) hisse "null-two" model - state INdependent diversification####
#Rates: 0A = 1A and 0B = 1B, hence it is called "null-two"

#transition rate matrix, this is not div rates, that is specified by turnover.anc
trans.rates.hisse.1 <- TransMatMaker(hidden.states=TRUE)
trans.rates.hisse.1 <- ParDrop(trans.rates.hisse.1, c(3,5,8,10)) 

#I am making all rates equal (the other way to do this is to keep 8 rates or 3 rates)
trans.rates.hisse.1[!is.na(trans.rates.hisse.1) & !trans.rates.hisse.1 == 0] = 1
#null_two_hisse <- hisse(pruned2, combo, f=samp, hidden.states=TRUE, turnover.anc=c(1,1,2,2), 
#                        eps.anc=c(1,1,2,2), trans.rate=trans.rates.hisse.1, output.type = "raw")
null_two_hisse_DEF <- hisse(pruned2, combo, f=samp, hidden.states=TRUE, turnover.anc=c(1,1,2,2),
                                eps.anc=c(1,1,2,2), trans.rate=trans.rates.hisse.1,root.p = c(0.5, 0, 0.5, 0), output.type = "raw")

####2) bisse like hisse model, separate turnover rates####
#only div rates for state 0 and state 1, and there are no hidden states
trans.rates.bisse <- TransMatMaker(hidden.states=FALSE)
#bisse_none_hidden <- hisse(pruned2, combo, hidden.states=FALSE, f=samp, turnover.anc=c(1,2,0,0), 
#                           eps.anc=c(1,2,0,0), trans.rate=trans.rates.bisse, output.type="raw")
bisse_none_hidden_DEF <- hisse(pruned2, combo, hidden.states=FALSE, f=samp, turnover.anc=c(1,2,0,0),
                                   eps.anc=c(1,2,0,0), trans.rate=trans.rates.bisse, root.p = c(0.5, 0, 0.5, 0), output.type="raw")

####3) null bisse, single turnover rate, pure bd model####
#div rates for state 0 and 1 are equal, and there are no hidden states
#bisse_null <- hisse(pruned2, combo, f=samp, hidden.states=FALSE, turnover.anc=c(1,1,0,0), 
#                    eps.anc=c(1,1,0,0), trans.rate=trans.rates.bisse, output.type="raw")
bisse_null_DEF <- hisse(pruned2, combo, f=samp, hidden.states=FALSE, turnover.anc=c(1,1,0,0),
                            eps.anc=c(1,1,0,0), trans.rate=trans.rates.bisse, root.p = c(0.5, 0, 0.5, 0), output.type="raw")

####4) hisse with only 1 hidden state####
trans.rates.hisse.3 <- TransMatMaker(hidden.states=TRUE)
trans.rates.hisse.3 <- ParDrop(trans.rates.hisse.3, c(2,3,5,7,8,9,10,12))
#hisse_1hidden_state <- hisse(pruned2, combo, f=samp, hidden.states=TRUE, turnover.anc=c(1,2,0,3), 
#                             eps.anc=c(1,2,0,3), trans.rate=trans.rates.hisse.3, output.type="raw")
hisse_1hidden_state_DEF <- hisse(pruned2, combo, f=samp, hidden.states=TRUE, turnover.anc=c(1,2,0,3),
                                     eps.anc=c(1,2,0,3), trans.rate=trans.rates.hisse.3, root.p = c(0.5, 0, 0.5, 0), output.type="raw")

####5) full hisse#####
trans.rates.hisse.4 <- TransMatMaker(hidden.states=TRUE)
trans.rates.hisse.4  <- ParDrop(trans.rates.hisse.4, c(3,5,8,10))
#full_hisse <- hisse(pruned2, combo, f=samp, hidden.states = TRUE, turnover.anc=c(1,2,3,4), 
#                    eps.anc=c(1,2,3,4), trans.rate = trans.rates.hisse.4, output.type = "raw")
full_hisse_DEF <- hisse(pruned2, combo, f=samp, hidden.states = TRUE, turnover.anc=c(1,2,3,4),
                            eps.anc=c(1,2,3,4), trans.rate = trans.rates.hisse.4, root.p = c(0.5, 0, 0.5, 0), output.type = "raw")

####6) null-four hisse####
null_four_hisse_DEF <- hisse.null4(pruned2, combo, f=samp, turnover.anc=rep(c(1,2,3,4),2),
                                  eps.anc=rep(c(1,2,3,4),2), trans.type="equal", root.p = c(0.5, 0, 0.5, 0), output.type = "raw")

