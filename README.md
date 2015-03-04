# M-SRM
Modified Snowmelt Runoff model for forecasting snowmelt in central northern Chile.

This repository was created as part of a 2013/2014 DEVELOP project for generating rough
forecasts of water availability as a result of snowmelt in central northern Chile.

Users wishing to use the M-SRM can download the contents of this repository in zip format.
It includes empty folders where NASA data must be downloaded and saved, that are otherwise
irrelevant to the codebase.

###Dependencies

Python 2.7

Matlab

Arcmap 10.1/10.2

This is a conglomeration of code writen in Python 2.7 and Matlab.
No cross language calls are made. Python code is executed sequentially to perform geospatial
data manipulations using the arcpy toolbox (comes with ESRI ArcMap), then saved outputs are
referenced by the matlab code (handled through the graphical user interface) to perform
the strictly numerical manipulations and analysis. 

Please reference the Tutoriales folder for Spanish and English help files.
