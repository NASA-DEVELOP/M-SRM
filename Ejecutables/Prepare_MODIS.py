#=================================================================
#               NASA_Prepar_MODIS.py código de controlar
#                       Nasa.py Terminal script
#-----------------------------------------------------------------
#
#(English)
#   Master script for interfacing with python contents of
#   NASA DEVELOP user package. Processes that the user does not wish
#   to run should be commented out.
#
# Descripciones de entrada
#   Package =   Filepath to NASA DEVELOP SRM folder
#   Year =      String value for desired year
#
# Valores de entrada ejemplo
#   Package =   'C:/Users/jwely/NASA_DEVELOP_TESTBED'
#   Year =      '2011'
#
#=================================================================
#                       valores de entrada de usuario
#                           User Input values
#-----------------------------------------------------------------

Package = r'C:/Users/jwely/Desktop/Chile/NASA_DEVELOP_SRM'
Year = '2014'

#=================================================================

# Import modules and begin timer functions
import nasa, time, sys
start = time.time()

# run the MODIS reprojection and mosaic tool
Package=Package.replace('\\','/')
nasa.Prepare_MODIS(Package,Year)

