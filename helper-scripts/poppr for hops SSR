###Using Poppr for dendrogram of Hops varities###

#1. set working directory, load packages, upload genotype table in GenAlEx required format and as .csv file 
install.packages("poppr")
install.packages("ape")
install.packages("mmod")

library(poppr)
library(ape)
library(mmod)

setwd("C:/Users/gmccarth/Desktop/KPU/Hops/Genotyping") # setwd command to set whatever your working directory is
S <- read.genalex("KPU_Hops_SSR.csv", ploidy = 4) # import genotypes in the GenAlex format
S <- read.genalex("KPU_Hops_SSR_2022crosses.csv", ploidy = 4)
S <- read.genalex("KPU_Hops_SSR_ExpandParents.csv", ploidy = 4)
genotype_curve(S, sample = 1000, quiet = TRUE) #gives a rarefaction type curve showing the # of genotypes vs the number of loci required to reach all observed genotypes
poppr(S) # lists all samples with diversity metrics
mlg.id(S) # lists ID of all samples, and if any samples share genotype
Gst_Hedrick(S) # genetic differentiation measure per loci, To account for the variation in the maximum obtainable GST, Hedrick (2005) proposed a "standardized" measure, G'ST, calculated by dividing GST for a given marker by the maximum theoretical GST based on the heterozygosity at that marker
repeatmotif <- c(2, 2, 5, 2, 2, 2, 2, 2, 3) # enter in the repeat motif bp length based on order of locus (left to right in table) from genotype table 
pthresh <- filter_stats(S, distance = bruvo.dist, replen = repeatmotif, plot = T, stats = "THRESHOLD") # find cutoff predicition for calling isolates the same based on bruvo distance
sapply(pthresh, cutoff_predictor)
mlg.filter(S, distance = "bruvo.dist", threads = 1L) <- 0.01
poppr(S)# find number of original MLGs after applying cutoff prediction
mlg.id(S) 

bruvo_dist <- bruvo.dist(S, replen = repeatmotif) #chose bruvo distance as bruvo distance takes into account microsatellites specifically for  polyploidy / missing or additonal alleles
bruvoTree <- bruvo_dist %>%
  nj() %>%    # calculate neighbor-joining tree
  ladderize() # organize branches by clade
plot(bruvoTree) # creates dendrogram
add.scale.bar(length = 0.05) # add the bruvo scale
set.seed(999)
bruvo.boot(pop = S, replen = repeatmotif, tree = "nj") # use bruvo distance to create a bootstrap for dendrogram. Scale created above. 0.05 distance means a 5 % difference in genotype, therefore, if two varities less than the distance, there is a less than 5% difference in their genotype. 


#plot unrooted tree
plot(unroot(bruvoTree),type="unrooted",no.margin=T,lab4ut="axial", edge.width=1,
     cex = .5, use.edge.length = T, label.offset = 0.25)
add.scale.bar(length = 0.05, ask = T)
set.seed(999)

bruvo.boot(pop = S, replen = repeatmotif, tree = "nj")

# k-means clustering of varieties within the tree

Sclust <- find.clusters(S) # choose the greatest number of PCs (prinicpal components to retain based on plot, chose 20 in this case
# next chose number of clusters from the value of BIC.BIC stands for "Bayesian Information Criterion". The lower the BIC value, the better. On the x axis are the number of clusters., only option was 2 
library("ape")
cols <- c("darkblue", "darkred")
plot.phylo(bruvoTree, cex = 0.8, font = 2, adj = 0, tip.color = cols[Sclust$grp],
           label.offset = 0.0125)
nodelabels(boot_tree$node.label, adj = c(2, -0.5), frame = "n", cex = 0.75,
           font = 3, xpd = TRUE)
axisPhylo(3) # bruvo distance scale above dendrogram


#plot unrooted tree with k-means clusters and bootstrapping
Sclust <- find.clusters(S)
set.seed(999)
boot_tree <- bruvo.boot(pop = S, replen = repeatmotif, tree = "nj", root = FALSE)
plot(boot_tree, type = "unrooted",no.margin=F,lab4ut="axial", edge.width=1,tip.color = cols[Sclust$grp] ,
     cex = 1, use.edge.length = T, label.offset = 0.03)
nodelabels(boot_tree$node.label, adj = c(1, 1), frame = "n", cex = 0.75,
           font = 3, xpd = TRUE)
add.scale.bar(ask = T, length = 0.05)


boot_tree <- bruvo.boot(pop = S, replen = repeatmotif, tree = "nj", root = FALSE, cutoff = 50)
plot(boot_tree, type = "unrooted",no.margin=F,lab4ut="axial", edge.width=1,
     cex = 0.8, use.edge.length = T, label.offset = 0.01, show.scale.bar = T, rotate.tree = 45)
nodelabels(boot_tree$node.label, adj = c(0, 1), frame = "n", cex = 0.6,
           font = 3, xpd = TRUE)
add.scale.bar(ask = T, length = 0.05)





