library(igraph)
# library(Matrix)
library(ggplot2)
setwd("~/Dropbox/Projects/module_space/R")
source("./net_proc.R")
source("./net_anlys.R")


###### Test for module density comparison ######
subj_list <- c('110411', '135932', '136833', '751348')
task_list <- c("rfMRI_REST1", "rfMRI_REST2")

M <- data.frame()
setwd("/home/dali/Dropbox/Projects/module_space/output/raw_net/")
for(s in subj_list){
  for(task in task_list){
    load(paste(s, task, "LR.RData", sep='_'))
    m <- cbind(rep(s, length(net_series)), rep(task, length(net_series)))
    for (rsn in 1:8) {
      sep_net <- lapply(net_series, function(g) induced.subgraph(g, which(V(g)$rsn7==rsn)))
      m <-  cbind(m, DensitySeries(sep_net), TransitivitySeries(sep_net))
    }
    M <- rbind(M, m)
  }
}
colnames(M) <- c("subject", "task", "visual_den", "visual_trans", "motor_den", "motor_trans", "dorsal_den", "dorsal_trans", "ventral_den", "ventral_trans", "limbic_den", "limbic_trans", "fp_den", "fp_trans", "DMN_den", "DMN_trans", "subcortical_den", "subcortical_trans")
for (x in 3:18) {
  M[,x] <- as.numeric(as.character(M[,x]))
}

plot(1:dim(data)[1], M$dorsal_den, type='l')
ggplot(M, aes(x=fp_den, y=dorsal_den, shape=subject, color=task))+geom_path() + xlim(0,1) + ylim(0,1) + coord_fixed()
p1 <- ggplot(M[M[,1]=="135932",], aes(x=fp_den, y=dorsal_den, color=task))+geom_path() + xlim(0,1) + ylim(0,1) + coord_fixed() + ggtitle("Subject 135932")
p2 <- ggplot(M[M[,1]=="110411",], aes(x=fp_den, y=dorsal_den, color=task))+geom_path() + xlim(0,1) + ylim(0,1) + coord_fixed() + ggtitle("Subject 110411")
p3 <- ggplot(M[M[,1]=="136833",], aes(x=fp_den, y=dorsal_den, color=task))+geom_path() + xlim(0,1) + ylim(0,1) + coord_fixed() + ggtitle("Subject 136833")
p4 <- ggplot(M[M[,1]=="751348",], aes(x=fp_den, y=dorsal_den, color=task))+geom_path() + xlim(0,1) + ylim(0,1) + coord_fixed() + ggtitle("Subject 751348")
multiplot(p1, p2, p3, p4, cols = 2)
ggplot(M[M[,2]=="rfMRI_REST1",], aes(x=visual_den, y=DMN_den, color=subject))+geom_path() + xlim(0,1) + ylim(0,1) + coord_fixed()
ggplot(M[M[,1]=="101915" & M[,2]=="tfMRI_MOTOR",], aes(x=dorsal_den, y=motor_den, color=task))+geom_point()+geom_path() + xlim(0,1) + ylim(0,1) + coord_fixed()

# Plotly
library(plotly)
library(statnet)
data <- M[M[,2]=="rfMRI_REST1",]
p <- plot_ly(data, x=~fp_den, y=~dorsal_den, z=rep(1:(dim(data)[1]/length(subj_list)), length(subj_list)), type = 'scatter3d', mode = 'lines', opacity = 1, color=~subject, line = list(width = 6, reverscale = FALSE))

data <- M[M[,2]=="rfMRI_REST1" & M[,1]=='135932',]
p <- plot_ly(data, x=~fp_den, y=~dorsal_den, z=1:(dim(data)[1]), type = 'scatter3d', mode = 'lines', opacity = 1, line = list(width = 6, reverscale = FALSE))
p

chart_link = api_create(p, filename="fp_dorsal_one")
###### Module comparison ends ######



###### Compare modularity and global efficiency ######
# Function area
Getf1f2 <- function(subj_list, nets_loc, sess, f1, f2){
  M <- data.frame(NULL)
  for (subj in subj_list) {
    net <- readRDS(paste(nets_loc, subj, '_', sess, '.rds', sep=''))
    if (!exists('l_time')) {
      l_time <- length(net)
    }
    m <- data.frame(subject=rep(subj, l_time))
    m <- cbind(m, m1=f1(net))
    m <- cbind(m, m2=f2(net))
    M <- rbind(M, m)
  }
  M
}

GetCommunity <- function(g){
  gmod <- cluster_fast_greedy(g)$membership
  set_vertex_attr(g, 'rsn7', value=gmod)
}
# Function area ends

subj_list <- c('211720', '151223', '103818', '127630')
sess <- "rfMRI_REST1_LR"
M360 <- Getf1f2(subj_list, '../output/nets_360f_t0/', sess, TransitivitySeries, ModuleSeries)
M90 <- Getf1f2(subj_list, '../output/nets_90f_t0/', sess, TransitivitySeries, ModuleSeries)
print(ggplot(M90, aes(x=m1, y=m2, color=subject))+geom_path() + xlim(.5,.8) + ylim(0,.3) + coord_fixed() + xlab('transitivity') + ylab('modularity') 
     + ggtitle("90 frames per snap"))
print(ggplot(M360, aes(x=m1, y=m2, color=subject))+geom_path() + xlim(.5,.8) + ylim(0,.3) + coord_fixed() + xlab('transitivity') + ylab('modularity') 
      + ggtitle("360 frames per snap"))

# Compare Email networks
karate_graph <- read_graph("/data/karate/karate.gml", format='gml')
karate_graph <- GetCommunity(karate_graph)
ggplot(M, aes(x=global_eff, y=modularity, color=subject))+geom_path() + xlim(0.25,.75) + ylim(0,.5) + coord_fixed() + 
  geom_point(aes(x=GlobalEff(karate_graph), y=modularity(karate_graph, V(karate_graph)$rsn7)))

# Compare Dolphin social networks
dolphin_graph <- read_graph("/data/dolphin/dolphins.gml", format='gml')
dolphin_graph <- GetCommunity(dolphin_graph)
ggplot(M, aes(x=global_eff, y=modularity, color=subject))+geom_path() + xlim(0,1) + ylim(0,1) + coord_fixed() + 
  geom_point(aes(x=GlobalEff(karate_graph), y=modularity(karate_graph, V(karate_graph)$rsn7)), colour='red') + 
  geom_point(aes(x=GlobalEff(dolphin_graph), y=modularity(dolphin_graph, V(dolphin_graph)$rsn7)), colour='blue')

# Compare the stock price networks
library(quantmod)
days <- 610
windowSize <- 360
cutoff <- .5

sp500_list <- read.csv("/home/dali/Desktop/sp500.csv", header = T)
start <- as.Date("2016-01-01")
end <- as.Date(Sys.Date())
all_prices <- NULL
all_companies <- NULL
for (company in sp500_list$Symbol) {
  stock_price <- loadSymbols(company, from=start, to=end, auto.assign = F)[,6]
  if (length(stock_price)==days && !anyNA(stock_price)) {
    all_companies <- c(all_companies, company)
    all_prices <- rbind(all_prices, as.numeric(stock_price))
  }
}
rsn7 <- sp500_list[sp500_list[,1] %in% all_companies, ]$Sector
ts <- all_prices
m <- dim(ts)[1]
n <- dim(ts)[2]
nwindows <- n-windowSize+1
matlist <- list()
for (i in 1:nwindows){
  corr_list <- rcorr(t(ts[, i:(i+windowSize-1)]), type='pearson')
  corrmat <- corr_list$r
  diag(corrmat) <- 0 
  matlist[[i]] <- corrmat
}
glist <- list()
for(i in 1:length(matlist)) {
  matlist[[i]][matlist[[i]] < cutoff] <- 0
  matlist[[i]][matlist[[i]] > cutoff] <- 1
  g <- graph_from_adjacency_matrix(matlist[[i]], mode = "undirected", diag=FALSE)
  g <- set_vertex_attr(g, "rsn7", value=rsn7)
  V(g)$color <- V(g)$rsn7
  glist[[i]] <- g
}
l_time <- length(glist)
m <- data.frame(subject=rep('stock', l_time))
m <- cbind(m, global_eff=GlobalEffSeries(glist))
m <- cbind(m, modularity=ModuleSeries(glist))

# Compare with ER graphs
for (count in 1:100) {
  g <- erdos.renyi.game(360, p=.05)
}

# Get some ERGM nets
library(ergm)
library(tergm)
library(intergraph)
subj <- sample(subj_list,1)
net <- all_nets[[subj]]

Msim <- data.frame(NULL)
for (subj in subj_list) {
  net <- all_nets[[subj]]
  msim <- NULL
  for (single_net in net) {
    g <- erdos.renyi.game(360, p=graph.density(single_net))
    g <- GetCommunity(g)
    msim <- rbind(msim, c(GlobalEff(g), modularity(g, V(g)$rsn7)))
  }
  Msim <- rbind(Msim, cbind(subject=rep(paste(subj, 'sim', sep = '_')), global_eff=as.numeric(msim[,1]), modularity=msim[,2]))
}

Msim$global_eff <- as.numeric(as.character(Msim$global_eff))
Msim$modularity <- as.numeric(as.character(Msim$modularity))

ggplot(M, aes(x=global_eff, y=modularity, color=subject))+geom_path() + xlim(0, .7) + ylim(0,.7) + coord_fixed() + 
  geom_point(aes(x=GlobalEff(karate_graph), y=modularity(karate_graph, V(karate_graph)$rsn7)), colour='red') +
  geom_point(aes(x=GlobalEff(dolphin_graph), y=modularity(dolphin_graph, V(dolphin_graph)$rsn7)), colour='blue') +
  geom_point(data=Msim, aes(x=global_eff, y=modularity),alpha=.1, size=.1)

ggplot(M, aes(x=global_eff, y=modularity, color=subject))+geom_path() + xlim(0.5, .7) + ylim(0,.2) + coord_fixed() + 
  geom_point(data=Msim, aes(x=global_eff, y=modularity),alpha=.1, size=.3)

ggplot(M[M$subject=="103818", ], aes(x=global_eff, y=modularity))+geom_path(alpha=seq(.2, 1, length.out=839)) + xlim(0.5, .7) + ylim(0,.2) + coord_fixed()
