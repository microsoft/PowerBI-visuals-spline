# Copyright (c) Microsoft Corporation.  All rights reserved.

# Third Party Programs. This software enables you to obtain software applications from other sources. 
# Those applications are offered and distributed by third parties under their own license terms.
# Microsoft is not developing, distributing or licensing those applications to you, but instead, 
# as a convenience, enables you to use this software to obtain those applications directly from 
# the application providers.
# By using the software, you acknowledge and agree that you are obtaining the applications directly
# from the third party providers and under separate license terms, and that it is your responsibility to locate, 
# understand and comply with those license terms.
# Microsoft grants you no license rights for third-party software or applications that is obtained using this software.


##PBI_R_VISUAL: VIZGAL_SPLINE   Visualization of spline interpolation
# Computes and visualizes a spline interpolation of 2D scatter 
# Smoothness is controlled by the user 
# INPUT: 
# The input dataset should include exactly two numerical non-constant columns for X and Y  
#
# EXAMPLES:
## for R environment
# library(zoo)
# library(reshape)
# dat=BJsales.lead  
# BJsaleData=data.frame(ind=index(dat),date=as.Date(dat),value=melt(dat)$value)
# dataset=data.frame(x=BJsaleData$ind,y=BJsaleData$value)
# source("visGal_spline.R") #create graphics
#
# WARNINGS:  
#
# CREATION DATE: 24/7/2016
#
# LAST UPDATE: 26/7/2017
#
# VERSION: 0.0.2
#
# R VERSION TESTED: 3.2.2
# 
# AUTHOR: pbicvsupport@microsoft.com
#
# REFERENCES: https://stat.ethz.ch/R-manual/R-devel/library/stats/html/loess.html

#save(list = ls(all.names = TRUE), file='C:/Users/boefraty/projects/PBI/R/tempData.Rda')
#load(file='C:/Users/boefraty/projects/PBI/R/tempData.Rda')


#PBI_EXAMPLE_DATASET for debugging purposes 


############ User Parameters #########
##PBI_PARAM: Should warnings text be displayed?
#Type:logical, Default:TRUE, Range:NA, PossibleValues:NA, Remarks: NA
showWarnings=TRUE

##PBI_PARAM Smoothness of spline. Small values correspond for wiggly spline, large values for smooth spline 
#Type: integer, Default:30, Range:[1,100], PossibleValues:NA, Remarks: Used to control "span" parameter 
smoothness = 30
if(exists("settings_spline_params_percentile")){
  smoothness = settings_spline_params_percentile
}

##PBI_PARAM Confidence level band display
#Type:logical, Default:TRUE, Range:NA, PossibleValues:NA, Remarks: NA
drawConfidenceLevels = TRUE
if(exists("settings_conf_params_showConf")){
  drawConfidenceLevels = settings_conf_params_showConf
}

###############Library Declarations###############
libraryRequireInstall = function(packageName, ...)
{
  if(!require(packageName, character.only = TRUE)) 
    warning(paste("*** The package: '", packageName, "' was not installed ***",sep=""))
}

libraryRequireInstall("reshape")
libraryRequireInstall("graphics")
libraryRequireInstall("splines")
libraryRequireInstall("scales")

###############Internal parameters definitions#################
#PBI_PARAM Minimal number of points for spline
#Type:integer, Default:7, Range:[3,100], PossibleValues:NA, Remarks: NA
minPoints = 7

##PBI_PARAM Confidence level percentage; 0.95 is 95%
#Type:numeric, Default:0.99, Range:[0,1], PossibleValues:NA, Remarks: NA
confLevel = 0.99
if(exists("settings_conf_params_confLevel")){
  confLevel = settings_conf_params_confLevel
}

##PBI_PARAM Color of scatterplot points
#Type:string, Default:"orange", Range:NA, PossibleValues:"orange","blue","green","black"
pointsCol = "orange"
if(exists("settings_scatter_params_pointColor")){
  pointsCol = settings_scatter_params_pointColor
}

##PBI_PARAM Color of spline plot
#Type:string, Default:"orange", Range:NA, PossibleValues:"orange","blue","green","black"
lineColor = "turquoise"
if(exists("settings_spline_params_lineColor")){
  lineColor = settings_spline_params_lineColor
}

#PBI_PARAM Transparency of scatterplot points
#Type:numeric, Default:0.4, Range:[0,1], PossibleValues:NA, Remarks: NA
transparency = 0.5

#PBI_PARAM Shaded band for confidence interval
#Type:logical, Default:TRUE, Range:NA, PossibleValues:NA, Remarks: NA
fillConfidenceLevels = TRUE

#PBI_PARAM Span for loess regression
#Type:numeric or NA, Default: NA, Range:(0.1,3], PossibleValues:NA, 
#Remarks: If span is NA or NULL the smoothness 
span = NA

#PBI_PARAM Size of points on the plot
#Type:numeric, Default: 1 , Range:[0.1,5], PossibleValues:NA, Remarks: NA
pointCex = 1
if(exists("settings_scatter_params_weight")){
  pointCex = settings_scatter_params_weight/10
}

###############Internal functions definitions#################


cutStr2Show = function(strText, strCex = 0.8, abbrTo = 100, isH = TRUE, maxChar = 3, partAvailable = 1)
{
  # partAvailable, wich portion of window is available, in [0,1]
  if(is.null(strText))
    return (NULL)
  
  SCL = 0.075*strCex/0.8
  pardin = par()$din
  gStand = partAvailable*(isH*pardin[1]+(1-isH)*pardin[2]) /SCL
  
  # if very very long abbreviate
  if(nchar(strText)>abbrTo && nchar(strText)> 1)
    strText = abbreviate(strText, abbrTo)
  
  # if looooooong convert to lo...
  if(nchar(strText)>round(gStand) && nchar(strText)> 1)
    strText = paste(substring(strText,1,floor(gStand)),"...",sep="")
  
  # if shorter than maxChar remove 
  if(gStand<=maxChar)
    strText = NULL
  
  return(strText) 
}


#if it attributeColumn is legal colors() use them 
#if all the entries in attributeColumn are the same number - use defaultColor
#if it has many numeric variables color from green to red range 
#if it has few unique strings - use rainbow to color them 
ColorPerPoint = function (attributeColumn, defaultColor = pointsCol, sizeColRange = 30)
{
  N = length(attributeColumn)
  if(sum(attributeColumn %in% colors()) == N) # all legal colors
    return(attributeColumn)
  
  UN = length(unique(attributeColumn))
  if(UN == 1) # single number 
    return(defaultColor)
  
  sortedUniqueValues = sort(unique(attributeColumn))
  
  if(UN >= N - 2 && is.numeric(attributeColumn)) # many numbers --> color range 
  {
    rangeColors = terrain.colors(sizeColRange)# 30 colors
    breaks = seq(min(sortedUniqueValues), max(sortedUniqueValues),length.out = sizeColRange + 1)
    pointsCol = as.character(cut(attributeColumn, breaks,labels = rangeColors))
    return(pointsCol)
  } else {
    rangeColors = rainbow(UN)
    names(rangeColors) = sortedUniqueValues
    return(rangeColors[as.character(attributeColumn)])
  }
}

###############Upfront input correctness validations (where possible)#################
pbiWarning = NULL

if (exists("x_var") && exists("y_var") && is.numeric(x_var[,1]) && is.numeric(y_var[,1])){

  if(exists("color")) {
    dataset=cbind(x_var,y_var,color)
  } else {
    dataset=cbind(x_var,y_var)
  }
  
  dataset<-dataset[complete.cases(dataset),] #remove corrupted rows
  
  if(is.null(span) || is.na(span))
    span=smoothness/50
  
  if(ncol(dataset) > 2)
    pointsCol = ColorPerPoint(dataset[,3],pointsCol)
  
  ##############Main Visualization script###########
  
  
  cNames <- names(dataset)
  
  if(nrow(dataset) >= minPoints) {
    
    names(dataset) = c("x", "y")
    
    #x=as.numeric(x[,1])
    #y=as.numeric(y[,1])
    
    attach(dataset)
    new.x = seq(min(dataset[, 1]), max(dataset[,1]), length.out = 100)
    
    fit <- tryCatch(
      {
        loess(y ~ x, family = "gaussian", span = span)
      },
      error=function(cond) {
        return(list())
      }
    )
    
    cNames[1] = cutStr2Show(cNames[1], strCex =1.1, isH = TRUE)
    cNames[2] = cutStr2Show(cNames[2], strCex =1.1, isH = FALSE)
    plot(x, y, xlim = c(min(x), max(x)), ylim=c(min(y), max(y)), pch = 19, cex = pointCex,
         ylab = cNames[2], xlab = cNames[1],col = alpha(pointsCol, transparency))
    
    if (length(fit) != 0) {     
      
      prediction = predict(fit, data.frame(x = new.x), se = TRUE)
      spline_plot = prediction$fit
      
      if (drawConfidenceLevels) {
        spline_plot = cbind(
          spline_plot,
          prediction$fit + (prediction$se.fit)*qnorm(1 - (1 - confLevel)/2),
          prediction$fit - prediction$se.fit*qnorm(1 - (1 - confLevel)/2)
        )
      }
      
      if (drawConfidenceLevels && fillConfidenceLevels) # add fill
        polygon(c(rev(new.x), new.x), c(rev(spline_plot[ ,3]), spline_plot[ ,2]), col = alpha('grey80',transparency), border = NA)
      
      matplot(new.x, spline_plot, lwd = c(3,1,1), lty = c(1,2,2), col = c(lineColor,"red","red"), type = "l", add = TRUE)
    } else {
      showWarnings = TRUE
      pbiWarning<-paste(pbiWarning, "Regression failed: possibly no pattern in data. ", sep="")
    }
  } else { # note enough points
    plot.new()
    pbiWarning<-paste(pbiWarning, "Not enough points for plot. ", sep="")
  }
} else{ #No X and Y columns
  plot.new()
  pbiWarning<-paste(pbiWarning, "Need numeric X and Y variables. ", sep="")
}

#add warning as subtitle
if(showWarnings)
{
  pbiWarning = cutStr2Show(pbiWarning, strCex = 0.75)
  title(main = NULL, sub = pbiWarning, outer = FALSE, col.sub = "gray50", cex.sub=0.75)
}
remove('dataset')

