#BAMM Analysis#

require(BAMMtools)
require(coda)
require(ape)

#Change working directory
setwd("~/working_folder_name")

####before running BAMM:####
#1) find priors
priors <- setBAMMpriors(read.tree("Newick_Species_Tree")) #these were added to the control file
#2) we also included proportions of missing data in our BAMM runs
#available in the supplementary csv file

####after running BAMM:####

#Import tree, this is same tree used in the BAMM analysis
#Species level phylogeny provided to us by Drs. Matthew Nelsen and Corrie Moreau
#the tree has already been pruned to match the taxa for which
#we have trait data available
tree <- read.tree("Newick_Species_Tree")

#import data for the combined plant mutualist trait
pm_traits <- read.csv("Plant_Mutualist_Trait_Data.csv", row.names = 1)

#Import data from BAMM run which used control_1.txt
mcmcout <- read.csv("mcmc_out_species_1.txt", header = T)

#Plot mcmc
dev.off()
plot(mcmcout$logLik ~ mcmcout$generation,pch=19)

#Check for convergence
burnstart <- floor(0.1 * nrow(mcmcout))
postburn <- mcmcout[burnstart:nrow(mcmcout), ]
mcmcout[burnstart:nrow(mcmcout),]

effectiveSize(postburn$logLik)
effectiveSize(postburn$N_shifts)

event <- getEventData(tree, "event_data_species_1.txt", burnin = 0.1)

#sort tips into which ones are mutualist vs non-mutualists
pm.sorted <- pm_traits[tree$tip.label,]
names(pm.sorted)<-tree$tip.label

sp.with.m<-as.character(names(pm.sorted)[pm.sorted==1])
sp.wo.m<-as.character(names(pm.sorted)[pm.sorted==0])

wholetree.nomBAMMpost<-subtreeBAMM(event,tips=sp.wo.m)
wholetree.mBAMMpost<-subtreeBAMM(event,tips=sp.with.m)

#retreive diversification rates for branches that are not mutualists
rateNoMut <- getCladeRates(wholetree.nomBAMMpost)
cat("whole tree No-Mut rate: mean",mean(rateNoMut$lambda-rateNoMut$mu),"sd",sd(rateNoMut$lambda-rateNoMut$mu))
cat("lamda: mean",mean(rateNoMut$lambda),"sd",sd(rateNoMut$lambda))
cat("mu: mean",mean(rateNoMut$mu),"sd",sd(rateNoMut$mu))

#retreive diversification rates for branches that are mutualists
rateMut <- getCladeRates(wholetree.mBAMMpost)
cat("whole tree Mut rate: mean",mean(rateMut$lambda-rateMut$mu),"sd",sd(rateMut$lambda-rateMut$mu))
cat("lamda: mean",mean(rateMut$lambda),"sd",sd(rateMut$lambda))
cat("mu: mean",mean(rateMut$mu),"sd",sd(rateMut$mu))

#differences between mutualist and non-mutualist#
cat("mean r1-r0:",mean((rateMut$lambda-rateMut$mu)-(rateNoMut$lambda-rateNoMut$mu)),"sd",sd((rateMut$lambda-rateMut$mu)-(rateNoMut$lambda-rateNoMut$mu)))

#STRAPP test
set.seed(1218)
STRAPP2 <- traitDependentBAMM(event, pm.sorted, reps = 10000, rate = "net diversification", return.full = TRUE, method = 'm', logrates = FALSE,
                              two.tailed = TRUE)
