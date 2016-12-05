########################################################
#
#Functions for handling connectivity Map (cMap) data. 
# Guillermo de Anda - Jauregui
# guillermo.deandajaur@med.und.edu
#
########################################################

###########
#Libraries#
###########
library("data.table")
library("stringr")
library("GeneExpressionSignature")
###########

######
# fread.Ranked.Matrix 
#Read Ranked Matrices
######

fread.Ranked.Matrix <- function(filepath){
  mx<-fread(filepath, data.table = FALSE)
  rownames(mx) = mx[,1]
  colnames(mx) = mx[1,]
  mx = mx[-1,-1]
  return(mx)
}

######
# drug.eset
# make an ExpressionSet of samples 
# perturbed by drugs on a list, 
# based on a file with sample information
######

drug.eset<- function(RankedMatrix, SampleInfoFile, DrugList){
  #Identify samples treated with drugs of interest
  DrugInstances = SampleInfoFile$instance_id[which(SampleInfoFile$normalized_name%in%DrugList)]
  #make a subset of the RankedMatrix, containing only these Ids
  Drug.RankMatrix = RankedMatrix[,as.character(DrugInstances)]
  #dummy eset, to force sample order
  eset = ExpressionSet(assayData = as.matrix(RankedMatrix))
  #make drug annotation object for the ExpressionSet
  DrugData = SampleInfoFile[which(SampleInfoFile$instance_id%in%colnames(exprs(eset))), c(1, 4)] #id, drugname
  rownames(DrugData) = DrugData[,1]
  DrugData = DrugData[,-1, drop = FALSE]
  DrugAFD = new("AnnotatedDataFrame", data = DrugData)
  #make the ExpressionSet
  eset = ExpressionSet(assayData = as.matrix(RankedMatrix), phenoData = DrugAFD)
  return(eset)
}

######
# cMap.eset
# make an ExpressionSet of samples 
# based on a file with cMap instance information
######

cMap.eset<- function(RankedMatrix, SampleInfoFile){
  #dummy eset, to force sample order
  eset = ExpressionSet(assayData = as.matrix(RankedMatrix))
  #make drug annotation object for the ExpressionSet
  cMapData = SampleInfoFile[which(SampleInfoFile$instance_id%in%colnames(exprs(eset))), ] 
  rownames(cMapData) = cMapData[,1]
  cMapData = DrugData[,-1, drop = FALSE]
  cMapAFD = new("AnnotatedDataFrame", data = cMapData)
  #make the ExpressionSet
  eset = ExpressionSet(assayData = as.matrix(RankedMatrix), phenoData = cMapAFD)
  return(eset)
}

######
# read.Drugs
# helper function to read and format a drug list file
# 
######

read.Drugs<- function(DrugList){
  drugList = read.table(file = DrugList)
  drugList = drugList$V1
  drugList = str_to_upper(drugList)
}

#######
# Drug.Gene.Graph
# Takes a Kru-Bor merged set of ranked differentially expressed genes 
# after drug treatment
# and a threshold
# Returns a directed, weighted network from DRUGS to GENES
#######

Drug.Gene.Graph <- function(MergedDrugEset, Threshold){
  DrugGraph = exprs(MergedDrugEset)
  minz = Threshold
  maxz = max(DrugGraph) - Threshold
  DrugGraph <- ifelse(minz>=DrugGraph | DrugGraph>maxz, 1, 0)
  DrugGraph = graph_from_incidence_matrix(incidence = DrugGraph, 
                                          directed = TRUE, 
                                          mode = "in")
  return(DrugGraph)
}