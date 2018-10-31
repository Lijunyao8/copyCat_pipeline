#project

library(copyCat)
library(configr) #dependencies
config <- read.config(file="/diskmnt/Projects/Users/lyao/CPTAC/copycat_pipeline/config_R.ini")
lapply(config,noquote)

runPairedSampleAnalysis(annotationDirectory=config$copycat$annotationDirectory,
outputDirectory=config$copycat$outputDirectory,
normal=config$copycat$normal,
tumor=config$copycat$tumor,
inputType=config$copycat$inputType,
maxCores=config$copycat$maxCores,
binSize=config$copycat$binSize, 
perLibrary=1,
perReadLength=config$copycat$perReadLength,
verbose=config$copycat$verbose,
minWidth=3,
minMapability=config$copycat$minMapability,
dumpBins=config$copycat$dumpBins,
doGcCorrection=config$copycat$doGcCorrection,
samtoolsFileFormat=config$copycat$samtoolsFileFormat,
purity=1,
normalSamtoolsFile=config$copycat$normalSamtoolsFile,
tumorSamtoolsFile=config$copycat$tumorSamtoolsFile)
