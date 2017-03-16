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
#
# WARNINGS:  
#
# CREATION DATE: 24/7/2016
#
# LAST UPDATE: 16/03/2017
#
# VERSION: 1.0.3
#
# R VERSION TESTED: 3.2.2
# 
# AUTHOR: pbicvsupport@microsoft.com
#
# REFERENCES: https://stat.ethz.ch/R-manual/R-devel/library/stats/html/loess.html

#DEBUG 
# fileRda = "C:/Users/boefraty/projects/PBI/R/tempData.Rda"
# if(file.exists(dirname(fileRda)))
# {
#   if(Sys.getenv("RSTUDIO")!="")
#     load(file= fileRda) 
#   else
#     save(list = ls(all.names = TRUE), file=fileRda)
# }


source('./r_files/flatten_HTML.r')

############ User Parameters #########
##PBI_PARAM: Should warnings text be displayed?
#Type:logical, Default:TRUE, Range:NA, PossibleValues:NA, Remarks: NA
showWarnings=TRUE

##PBI_PARAM Smoothness of spline. Small values correspond for wiggly spline, large values for smooth spline 
#Type: integer, Default:30, Range:[1,100], PossibleValues:NA, Remarks: Used to control "span" parameter 
smoothness = 30
if(exists("settings_spline_params_percentile")){
  smoothness = max(1,settings_spline_params_percentile)
}

##PBI_PARAM Confidence level band display
#Type:logical, Default:TRUE, Range:NA, PossibleValues:NA, Remarks: NA
drawConfidenceLevels = TRUE
if(exists("settings_conf_params_show")){
  drawConfidenceLevels = settings_conf_params_show
}

##PBI_PARAM Confidence level percentage; 0.95 is 95%
#Type:numeric, Default:0.99, Range:[0,1], PossibleValues:NA, Remarks: NA
confLevel = 0.99
if(exists("settings_conf_params_confLevel")){
  confLevel = max(0.25,min(settings_conf_params_confLevel,1))
}

##PBI_PARAM Color of scatterplot points
#Type:string, Default:"orange", Range:NA, PossibleValues:"orange","blue","green","black"
pointsCol = "orange"
if(exists("settings_scatter_params_pointColor")){
  pointsCol = settings_scatter_params_pointColor
}

##PBI_PARAM Color of spline plot
#Type:string, Default:"orange", Range:NA, PossibleValues:"orange","blue","green","black"
lineColor = "red"
if(exists("settings_spline_params_lineColor")){
  lineColor = settings_spline_params_lineColor
}

#PBI_PARAM Transparency of scatterplot points
#Type:numeric, Default:0.4, Range:[0,1], PossibleValues:NA, Remarks: NA
transparency = 0.4
if(exists("settings_scatter_params_percentile")){
  transparency = settings_scatter_params_percentile/100
}



###############Library Declarations###############
libraryRequireInstall("reshape")
libraryRequireInstall("graphics")
libraryRequireInstall("splines")
libraryRequireInstall("scales")

# HTML widget
libraryRequireInstall("ggplot2")
libraryRequireInstall("plotly")


###############Internal parameters definitions#################
#PBI_PARAM Minimal number of points for spline
#Type:integer, Default:7, Range:[3,100], PossibleValues:NA, Remarks: NA
minPoints = 7


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
  pointCex = min(50,max(settings_scatter_params_weight,1))/10
}

#PBI_PARAM Size of labels on axes
sizeLabel = 12

#PBI_PARAM Size of warnings font
sizeWarn = 11

#PBI_PARAM Size of ticks on axes 
sizeTicks = 8

#PBI_PARAM opacity of conf interval color
transparencyConfInterval = 0.4 


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
  ccd = complete.cases(dataset)
  dataset<-dataset[ccd,] #remove corrupted rows
  if(exists("tooltips"))
    tooltips[,1] = as.character(tooltips[ccd,1])
  
  if(is.null(span) || is.na(span))
    span=smoothness/50
  
  if(ncol(dataset) > 2)
    pointsCol = ColorPerPoint(dataset[,3],pointsCol)
  
  ##############Main Visualization script###########
  
  cNames <- names(dataset)
  
  if(nrow(dataset) >= minPoints) {
    
    names(dataset) = c("x", "y")
    
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
    
    
    g = ggplot()
    if(pointCex > 0)
    {
      pointDF = data.frame(x = x, y = y); #names(pointDF) = cNames[1:2]
      
      g = ggplot(data = pointDF, aes(x,y)) +  geom_point(data = pointDF, mapping = aes(x = x, y = y),
                                                         size = pointCex*2, colour = alpha(pointsCol, transparency), inherit.aes = FALSE)  
    }
    
    
    cNames1 = cutStr2Show(cNames[1], strCex = sizeLabel/6, isH = TRUE, partAvailable = 0.8)
    cNames2 = cutStr2Show(cNames[2], strCex = sizeLabel/6, isH = FALSE, partAvailable = 0.8)
    
    g = g + labs (title =NULL) + xlab(cNames1) + ylab(cNames2) + theme_bw() #only scatter  
    
    
    if (length(fit) != 0) {     
      
      prediction = predict(fit, data.frame(x = new.x), se = TRUE)
      spline_plot = prediction$fit
      dfSpline = data.frame(x = new.x,y = spline_plot)
      
      g = g + geom_path(aes(x = x, y = y), data = dfSpline, colour = lineColor, size = 1.5, inherit.aes = FALSE)# spline 
      
      
      if (drawConfidenceLevels) {
        spline_plot = cbind(
          spline_plot,
          prediction$fit + (prediction$se.fit)*qnorm(1 - (1 - confLevel)/2),
          prediction$fit - prediction$se.fit*qnorm(1 - (1 - confLevel)/2)
        )
      }
      
      if (drawConfidenceLevels && fillConfidenceLevels) # add fill
      {
        dfPoly = data.frame(X = c(new.x,rev(new.x)), Y = c(spline_plot[ ,3], rev(spline_plot[ ,2])))
        
        g = g +
          geom_path(aes(x = x, y = y), data = data.frame(x = new.x,y = spline_plot[,2]), colour = "red", size = 0.25, linetype = 2, inherit.aes = FALSE) + 
          geom_path(aes(x = x, y = y), data = data.frame(x = new.x,y = spline_plot[,3]), colour = "red", size = 0.25, linetype = 2, inherit.aes = FALSE) + 
          geom_polygon(data = dfPoly ,  
                       mapping = aes(x = X, y = Y), 
                       alpha = transparencyConfInterval, fill = 'grey80')  # add cofidence levels 
      }
      
      
    } else {
      showWarnings = TRUE
      pbiWarning1 = "Regression failed: possibly no pattern in data. "
      pbiWarning1 = cutStr2Show(pbiWarning1, strCex = sizeWarn/6, partAvailable = 0.85)
      pbiWarning<-paste(pbiWarning, pbiWarning1, sep="")
    }
  } else { # note enough points
    g = ggplot()
    pbiWarning1 = "Not enough points for plot."
    pbiWarning1 = cutStr2Show(pbiWarning1, strCex = sizeWarn/6, partAvailable = 0.85)
    pbiWarning<-paste(pbiWarning, "<br>", pbiWarning1, sep="")
  }
} else{ #No X and Y columns
  g = ggplot()
  pbiWarning1 = "Need numeric X and Y variables."
  pbiWarning1 = cutStr2Show(pbiWarning1, strCex = sizeWarn/6, partAvailable = 0.85)
  pbiWarning<-paste(pbiWarning, "<br>", pbiWarning1, sep="")
}

#add warning as title

g = g + labs (title = pbiWarning, caption = NULL) + theme_bw() +
  theme(plot.title  = element_text(hjust = 0.5, size = sizeWarn), 
        axis.title=element_text(size =  sizeLabel),
        axis.text=element_text(size =  sizeTicks),
        panel.border = element_blank())



if(length(g$layers) == 5)
{
  g$layers = g$layers[c(3,4,5,1,2)]
  layerScatter = 4
}
if(length(g$layers) == 3)
{
  g$layers = g$layers[c(3,2,1)]
  layerScatter = 2
  
}
if(length(g$layers) == 2)
{
  layerScatter = 1
}

p <- plotly_build(g)


if(showWarnings && !is.null(pbiWarning))
  p$x$layout$margin$l = p$x$layout$margin$r = 0 

if(length(g$layers)>0)
{
  p$x$data[[layerScatter]]$text = paste (cNames[1],": ",p$x$data[[layerScatter]]$x, "<br>",
                                         cNames[2],": ",p$x$data[[layerScatter]]$y)
  
  if(exists("tooltips")) 
    p$x$data[[layerScatter]]$text = paste(p$x$data[[layerScatter]]$text, "<br>",
                                          names(tooltips)[1],": ",tooltips[,1], sep ="")
}

############# Create and save widget ###############


disabledButtonsList <- list('toImage', 'sendDataToCloud', 'zoom2d', 'pan', 'pan2d', 'select2d', 'lasso2d', 'hoverClosestCartesian', 'hoverCompareCartesian')
p$x$config$modeBarButtonsToRemove = disabledButtonsList
p <- config(p, staticPlot = FALSE, editable = FALSE, sendData = FALSE, showLink = FALSE,
            displaylogo = FALSE,  collaborate = FALSE, cloud=FALSE)

internalSaveWidget(p, 'out.html')
####################################################

# display in R studio
# if(Sys.getenv("RSTUDIO")!="")
#  print(p)
