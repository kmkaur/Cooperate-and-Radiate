#BiSSE Species Plant Mutualist Analysis#

require(ape)
require(geiger)
require(diversitree)
require(phangorn)
require(phytools)

#Change working directory
setwd("~/working_folder_name")

#####Loading the species tree#####

#load Nelsen et al 2018 species tree
#tree is already pruned to match trait information
tree<-read.newick(file="Newick_Species_Tree")
plot(tree, "fan", cex=0.5)

#remove underscores, clean up tip names
genus <- sapply(strsplit(as.character(tree$tip.label), '_'), function(x) x[1])
species <- sapply(strsplit(as.character(tree$tip.label), '_'), function(x) x[2])
tree$tip.label<-paste(genus, species, sep = " ")

#import trait data on the species level for the combined
#plant mutualist category
taxa <- read.csv("All_Terms_Species.csv", row.names=1)

#match up data between tree and trait data
TreeOnly <- setdiff(tree$tip.label,rownames(taxa))
DataOnly <- setdiff(rownames(taxa), tree$tip.label)

pruned<-drop.tip(tree, TreeOnly)
plot(pruned, "fan", cex=0.5)

taxa2 <- as.matrix(taxa)
taxa3<-taxa2[-match(DataOnly, rownames(taxa2)),]

######Bisse######

#make tree ultrametric to run in BiSSE
pruned2<-nnls.tree(cophenetic(pruned),pruned,rooted=TRUE)

#convert data to bisse format
treedata(pruned2,taxa,sort=TRUE)
combo <-taxa[pruned2$tip.label,]
names(combo)<-pruned2$tip.label
plot(pruned2,tip.color=combo+1,cex=0.1)
tree$tip.state<-combo

#bisse parameters
samp <- c(0.04780, 0.1046)
p <- starting.point.bisse(tree = pruned2)
full.lik <- make.bisse(pruned2, states = combo, sampling.f = samp)

full.mle <- find.mle(full.lik, p, method = "subplex", root.p = c(1,0), root = ROOT.GIVEN)
par <- full.mle$par

#make the prior exponentially distributed
prior <- make.prior.exponential(1 / (2 * (p[1] - p[3])))

#run preliminary MCMC with 0.1 tuning parameter
mcmc.bisse<-mcmc(full.lik, par, nsteps=1000,prior=prior,w=0.1)

head(mcmc.bisse) #check

w=diff(sapply(mcmc.bisse[2:7],quantile,c(0.05,0.95)))

#Run the final MCMC
mcmc.bisse2<-mcmc(full.lik,par,nsteps=10000,w=w,prior=prior)
write.csv(mcmc.bisse2,"mcmcbisse_species_all_data.csv")
saveRDS(mcmc.bisse2, file="mcmcbisse_species_all_data.rds")

