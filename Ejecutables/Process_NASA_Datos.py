#=================================================================
#                Process_NASA_Datos.py código de controlar
#                Process_NASA_Datos.py Terminal script
#-----------------------------------------------------------------
#(Espanol)
#   Script para interactuar con el contenido de pitón de la NASA
#   DEVELOP paquete usuario. Los procesos que el usuario no desea
#   ejecutar deben ser comentadas.
#
#(English)
#   Master script for interfacing with python contents of
#   NASA DEVELOP user package. Processes that the user does not wish
#   to run should be commented out.
#
# Descripciones de entrada
#   Package =   Filepath to NASA DEVELOP SRM folder
#   Basins =    Folder containing basins to analyze
#   Years =     String value for desired years
#   zonefield=  Name of field for basin shapefile designating all
#                area over 2000 meters where precipitation inputs
#                are to be applyed from TRMM (or GPM) calculations.
#
# vValores de entrada ejemplo
#   Package =   'C:/Users/jwely/NASA_DEVELOP_TESTBED'
#   Basins =    ['Coquimbo_Limari','Atacama_Huasco','Atacama_Copiapo']
#   Years =     ['2013','2014']
#   zonefield = 'NASA'
#
#=================================================================
#                           User Input values
#-----------------------------------------------------------------
Package = r'C:\Users\jwely\Desktop\Chile\NASA_DEVELOP_SRM'
Basins = 'Coquimbo_Limari'
Years = '2014'
zonefield =  'NASA'
#=================================================================

# Import modules and begin timer functions
import nasa, time, sys
start = time.time()

# make sure all input parameters are valid formats
Package=Package.replace('\\','/')

if not isinstance(Basins,list) and Basins:
    Basins=[Basins]
    
if not isinstance(Years,list) and Years:
    Years=[Years]

# for all desired basins and years, perform MODIS and TRMM processing
# GPM capabilities not yet included!
for Basin in Basins:
    for Year in Years:
        Year=str(Year)
        print '==================================================='
        print 'Begin processing of',Basin,' for year',Year

        # Process MODIS data  

        nasa.Process_MODIS(Package,Basin,Year)
        end=time.time()
        print 'Elapsed Time: ' + str((end - start)/60) + ' minutes'

        #print 'Failed to process MODIS for ',Basin,' for year', Year
            
        # Process TRMM data           
        try:
            # HighShape.shp was changed to HighShape.tif due to a strange
            # issue with Arcmap 10.2 vs 10.1. Now zonefield is 'Value'
            zonefield =  'Value' 
            nasa.Process_TRMM(Package,Basin,Year,zonefield)
            end=time.time()
            print 'Elapsed Time: ' + str((end - start)/60) + ' minutes'
            
        except:
            print 'Failed to process TRMM for ',Basin,' for year', Year
            
        print '==================================================='

