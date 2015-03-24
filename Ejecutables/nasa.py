"""
Much of this script was pieced together from code writen in Fall 2013 and
Spring 2014 DEVELOP terms. Drastic improvements were made by pulling new pieces
from the DEVELOP National Program Python Module (dnppy) but the code
still needs a lot of tender love and care to bring to something of
professional quality. As the code is now open source, feel free to do so.
"""

def Prepare_MODIS(Package,Year):

    import os

    Year=str(Year)
    rawmodis = Package + '/Datos/NASA_Datos/MODIS/' + Year
    readymodis = rawmodis + '/prm'
    reference_file=os.path.join(Package,'Ejecutables\Reference\Elev_Zones.tif')

    if not os.path.exists(readymodis):
        os.makedirs(readymodis)

    # Extract all the HDFs in the specified year for the given basin.
    hdf_list = List_Files(False,rawmodis,['.hdf'],['.xml','.ovr','.aux'],False) 
    Extract_MODIS_HDF(hdf_list,[3],['Fractional_Snow_Cover'],rawmodis,False)

    # Mosaic all possible MODIS tiles together.  
    mosaic_list = List_Files(False,rawmodis,['.tif','Fractional_Snow_Cover'],['.xml','.ovr','.aux'],False)
    Mosaic_MODIS(mosaic_list, '8_BIT_UNSIGNED', '1', 'LAST','FIRST',readymodis,False)

    # reprojects all files to the desired projection.
    project_list = List_Files(False,readymodis,['mosaic','.tif'],['.xml','.ovr','.aux'],False)
    Project_Filelist(project_list,reference_file,readymodis,False,False,Quiet=False)
    
    return

#=========================================================================================================
def Process_MODIS(Package,Basin,Year):
    
    # assembling the list of file addresses 
    Dir = Package + '/Datos/Cuencas/'+ Basin + '/Datos_Intermedia/MODIS/' + Year
    ModisData = Package + '/Datos/NASA_Datos/MODIS/' + Year + '/prm'
    Shapefile = Package + '/Datos/Cuencas/' + Basin + '/Parametros/Shapefile/Shape.shp'

    # import modules and create temporary folders
    import arcpy, os
    arcpy.env.workspace = ModisData
    arcpy.env.overwriteOutput = True

    if not os.path.exists(Dir + '/temp'):
        os.makedirs(Dir + '/temp')

    # open meta.txt file and read out the value of the clip box.
    # meta file must be created during basin characterization by coppying the extents of basin shapefile.
    meta = open(Package + '/Datos/Cuencas/'+ Basin + '/Meta.txt','r')
    ClipBox = meta.read().split(':')[1].replace('Basin_Area','')
    print 'Process_MODIS: ClipBox set to ' + ClipBox
        
    # Grab a list of all the tifs in the folder meeting the META criteria of the basin
    Tiffs = List_Files(False,ModisData,['mosaic','Fractional_Snow_Cover_p.tif'],['.xml','.ovr','.aux'],True)
    print 'Process_MODIS: Disocvered ' + str(len(Tiffs)) +' tifs'

    for filename in Tiffs:
        print 'Process_MODIS: Clipping and resampling ' + filename

        path, name = os.path.split(filename)
        
        clip_tif      = Dir + '/temp/clipped.tif'
        resampled_tif = Dir + '/RS_' + name[:-4] + '.tif'
        
        arcpy.Clip_management(filename, ClipBox, clip_tif, Shapefile, "255", "ClippingGeometry")
        arcpy.Resample_management(clip_tif, resampled_tif, '29.10712091 29.10712091' , "NEAREST")

    print 'Process_MODIS: Finished processing year ' + str(Year)
    
#=========================================================================================================
def Process_TRMM(Package,Basin,Year,zoneField):

    # assembling the list of file addresses 
    TRMM_path= Package + '/Datos/NASA_Datos/TRMM/' + Year
    inZoneData = Package + '/Datos/Cuencas/' + Basin + '/Parametros/Shapefile/HighShape.tif'
    OutputTRMM = Package + '/Datos/Cuencas/' +Basin + '/Datos_Intermedia/TRMM/TRMM_Precip' + Year +'.dbf'
    OutputTRMMpath = Package + '/Datos/Cuencas/' +Basin + '/Datos_Intermedia/TRMM'

    #import modules and manage temporary folders
    import arcpy, arcgisscripting, sys, os, csv, string, shutil
    from arcpy import env
    from arcpy.sa import *
    try:
        from dbfpy import dbf
    except:
        print 'You do not have "dbfpy" installed, Process_TRMM cannot run!'
        return
    
    arcpy.env.overwriteOutput = True
    arcpy.SetLogHistory(True)
    arcpy.CheckOutExtension("Spatial")
    
    IntermediateOutput = TRMM_path + '/temp'

    # make sure the TRMM output path is there
    if not os.path.exists(OutputTRMMpath):
        os.makedirs(OutputTRMMpath)

    # If a temp data folder already exists, delete its contents and recreate it. 
    if os.path.exists(IntermediateOutput):
        shutil.rmtree(IntermediateOutput)
        os.makedirs(IntermediateOutput)
    else:

    ###### If no temporary folder exists, NetCDFs are converted to tiffs for the first time.
        os.makedirs(IntermediateOutput)
        arcpy.env.workspace = TRMM_path
        arcpy.env.overwriteOutput = True

        NCfiles = arcpy.ListFiles("*.nc")

        for filename in NCfiles:
            print 'Process_TRMM: Converting netCDF file ' + filename + ' to Raster'
            inNCfiles = arcpy.env.workspace + "/" + filename
            fileroot = filename[0:(len(filename)-3)]
            outRasterLayer = TRMM_path + "/" + fileroot
            arcpy.MakeNetCDFRasterLayer_md(inNCfiles, "r", "longitude", "latitude", "r", "", "", "BY_VALUE")   
            arcpy.CopyRaster_management("r", outRasterLayer + ".tif", "", "", "", "NONE", "NONE", "")

        print 'Process_TRMM: Finished creating TIFs!'
    #######

    # Execute zonal statistics functions on selected basin and store output as a dbf.
    arcpy.env.workspace = TRMM_path
    TIFfiles = arcpy.ListFiles("*.tif")
    
    try:
        for filename in TIFfiles:
            fileroot = filename[0:(len(filename)-4)]
            print "Process_TRMM: Calculating zonal statistics on " + filename
            inValueRaster = TRMM_path + '/'+  filename
            arcpy.CheckOutExtension("Spatial")
            tempout=IntermediateOutput + '/tempdbf.dbf'
            outZstat = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, tempout, "DATA", "ALL")

            # arcmap is a terribly programmed software package, so we have
            # save the output dbf as a static filename then rename it appropriately here.
            # this took forever to figure out (and we think it has something to do with "." in filename)
            outTable = IntermediateOutput + "/" + fileroot + '.dbf'
            os.rename(tempout,outTable)
            
        print 'Process_TRMM: Finished calculating zonal statistics!'

    except:
        print 'Error: Process_TRMM: Error encountered while calculating zonal statistics!'

    # Create csvs from DBFs
    arcpy.env.workspace = IntermediateOutput
    DBFfiles = arcpy.ListFiles("*.dbf")

    try:
        for filename in DBFfiles:
            fileroot = filename[0:(len(filename)-4)]
            
            # replace the '.' with '_', because the merge function is apparently very finicky with inputs.
            csv_fn = IntermediateOutput + '/' + string.replace(fileroot, '.', '_') + '.csv'
            
            inDBFfiles = arcpy.env.workspace + '/' + filename   
            with open(csv_fn,'wb') as csvfile:
                in_db = dbf.Dbf(inDBFfiles)
                out_csv = csv.writer(csvfile)
                names = []
                for field in in_db.header.fields:
                    names.append(field.name)
                out_csv.writerow(names)
                for rec in in_db:
                    out_csv.writerow(rec.fieldData)
                in_db.close()

        print 'Process_TRMM: Finished conversion to CSVs!'
    except:
        print 'Error: Process_TRMM: Error encountered while creating CSVs from dbfs!'

        
    # Merge CSVs together and print a bunch of progress items.
    arcpy.env.workspace = IntermediateOutput
    CSVfiles = arcpy.ListFiles("*.csv")

    print 'Process_TRMM: Creating Output file at ' + OutputTRMM
    print 'Process_TRMM: This may take up to 15 minutes' 
    arcpy.env.workspace = IntermediateOutput
    CSVfiles = arcpy.ListFiles("*.csv")
    arcpy.Merge_management(CSVfiles, OutputTRMM)

    print 'Process_TRMM: Output file created for year ' + Year

#======================================================================================
def Mosaic_MODIS(filelist, pixel_type, bands, m_method, m_colormap, outdir=False,Quiet=False):
#--------------------------------------------------------------------------------------
# This script will find and mosaic all MODIS tiles groups with different time names in a
# directory. It will automatically identify the date ranges in the MODIS filenames and
# iterate through the entire range while skipping dates for which there are not at least
# two tiles. Users should be mindful of file suffixes from previous processing.
#
# This script centers around the 'arcpy.MosaicToNewRaster_management' tool
# [http://help.arcgis.com/en/arcgisdesktop/10.0/help/index.html#//001700000098000000]
#
# Inputs:
#   indir           the directory containing MODIS data, will search recursively.
#   pixel_type      exactly as the input for the MosaicToNewRaster_management tool
#   bands           exactly as the input for the MosaicToNewRaster_management tool
#   m_method        exactly as the input for the MosaicToNewRaster_management tool
#   m_colormap      exactly as the input for the MosaicToNewRaster_management tool
#   contains        additional search criteria for deciding which MODIS tiles to mosaic
#                   This is required when the same directory contains multiple extracted
#                   layers from the MODIS HDF file. (unless the user decides to treat
#                   the multiple layers as bands in the same image stack)
#   outdir          the directory to save output files to. If none is specified, a
#                   default directory will be created as '[indir]_Mosaicked'
#   Quiet           True to silence output, defaults to False.
#
# Outputs:
#   failed          mosaic opperations which failed due to one or more missing tiles
#
# Example usage:
#
#       import ND
#       indir=      r'C:\Users\jwely\Desktop\Shortcuts\Testbed\Test tiles\MODIS LST\2013\day'
#       pixel_type= "16_BIT_UNSIGNED"
#       bands=      "1"
#       m_method=   "LAST"
#       m_colormap= "FIRST"
#
#       ND.Mosaic_MODIS_Dir(filelist,pixel_type,bands,m_method,m_colormap,'day')
#--------------------------------------------------------------------------------------
    # typically unchanged parameters of raster dataset. Change at will.
    coordinatesys="#"
    cellsize="#"

    # import modules
    import sys, os, arcpy, time

    # Set up initial arcpy modules, workspace, and parameters, and sanitize inputs.
    Check_Spatial_Extension()
    arcpy.env.overwriteOutput = True
    if outdir: OUT=outdir

    # initialize empty lists for tracking
    mosaiclist=[]
    yearlist=[]
    daylist=[]
    productlist=[]
    tilelist=[]
    failed=[]

    # grab info from all the files left in the filelist.
    for item in filelist:
        info=Grab_Data_Info(item,False,True)
        yearlist.append(int(info.year))
        daylist.append(int(info.j_day))

        # find all tiles being represented
        if info.tile not in tilelist:
            tilelist.append(info.tile)
            
        # find all MODIS products existing
        if info.product not in productlist:
            productlist.append(info.product)
            
    # define the range of years and days to look for
    years=range(min(yearlist),max(yearlist)+1)
    days=range(min(daylist),max(daylist)+1)

    # print some status updates to the screen
    if not Quiet:
        print '{Mosaic_MODIS} Found tiles : ' + str(tilelist)
        print '{Mosaic_MODIS} Found tiles from years: ' + str(years)
        print '{Mosaic_MODIS} Found tiles from days:  ' + str(days)
        print '{Mosaic_MODIS} Found tiles from product: ' + str(productlist)
    #.....................................................................................
    # now that we know what to look for, lets go back through and mosaic everything
    for product in productlist:
        for year in years:
            for day in days:

                # build the search criteria
                search=[(product +'.A'+ str(year)+str(day).zfill(3))]
                
                # find files meeting the criteria and sanitize list from accidental metadata inclusions
                for filename in filelist:
                    if all(x in filename for x in ['.tif']+search):
                        if not any(x in filename for x in ['.aux','.xml','.ovr','mosaic']):
                            mosaiclist.append(filename)
                

                # only continue with the mosaic if more than one file was found!
                if len(mosaiclist)>1:
                
                    # if user did not specify an outdir, make folder next to first mosaic file
                    if not outdir:
                        head,tail=os.path.split(mosaiclist[0])
                        OUT=os.path.join(head,'Mosaicked')

                    # make the output directory if it doesnt exist already    
                    if not os.path.isdir(OUT):
                        os.makedirs(OUT)

                    # grab suffix from input files for better naming of output files
                    info=Grab_Data_Info(mosaiclist[0],False,True)
                    suffix=info.suffix.split('_')[1:]
                    
                    # define the output name based on input criteria
                    path,filename= os.path.split(mosaiclist[0])
                    outname = '.'.join(search+['mosaic'])
                    outname = '_'.join([outname] +suffix)
                    
                    # perform the mosaic!
                    try:
                        arcpy.MosaicToNewRaster_management(mosaiclist,OUT,\
                            outname,coordinatesys,pixel_type,cellsize,bands,\
                            m_method,m_colormap)
                           
                        # make sure the mosaic list is empty!
                        if not Quiet: print outname +' mosaciked!'
                        
                    except:
                        if not Quiet: print '{Mosaic_MODIS} Failed to mosaic files! ' + outname
                        failed=failed+mosaiclist
                        
                # do not attempt a mosaic if only one tile on given day exists!    
                elif len(mosaiclist)==1:
                    if not Quiet:
                        print('{Mosaic_MODIS} More than one file is required for mosaicing!: '
                              + str(search))
                    failed=failed+mosaiclist

                # delete the list of search parameters for this mosaic operation
                del search[:]
                del mosaiclist[:]

                    
    if not Quiet:print '{Mosaic_MODIS} Finished!'
    return(failed)

#======================================================================================
def Extract_MODIS_HDF(filelist,layerlist,layernames=False,outdir=False,Quiet=False):
#--------------------------------------------------------------------------------------
# Function extracts tifs from HDFs such as MODIS data.
#
# inputs:
#   filelist    list of '.hdf' files from which data should be extracted
#   layerlist   list of layer numbers to pull out as individual tifs should be integers
#               such as [0,4] for the 0th and 4th layer respectively.
#   layernames  list of layer names to put more descriptive names to each layer
#   outdir      directory to which tif files should be saved
#               if outdir is left as 'False', files are saved in the same directory as
#               the input file was found.
#--------------------------------------------------------------------------------------

    # import modules
    import sys, os, arcpy, time

    # Set up initial arcpy modules, workspace, and parameters, and sanitize inputs.
    Check_Spatial_Extension()
    arcpy.env.overwriteOutput = True

    # enforce lists for iteration purposes
    filelist=Enforce_List(filelist)
    layerlist=Enforce_List(layerlist)
    layernames=Enforce_List(layernames)
    
    # ignore user input layernames if they are invalid, but print warnings
    if layernames and not len(layernames)==len(layerlist):
        print '{Extract_MODIS_HDF} layernames must be the same length as layerlist!'
        print '{Extract_MODIS_HDF} ommiting user defined layernames!'
        layernames=False

    # create empty list to add failed file names into
    failed=[]

    print '{Extract_MODIS_HDF} Beginning to extract!'
    # iterate through every file in the input filelist
    for infile in filelist:
        # pull the filename and path apart 
        path,name = os.path.split(infile)
        arcpy.env.workspace = path

        for i in range(len(layerlist)):
            layer=layerlist[i]
            
            # specify the layer names.
            if layernames:
                layername=layernames[i]
            else:
                layername=str(layer).zfill(3)

            # use the input output directory if the user input one, otherwise build one  
            if not os.path.exists(outdir):
                os.makedirs(outdir)
                
            outname=os.path.join(outdir,name[:-4] +'_'+ layername +'.tif')

            # perform the extracting and projection definition
            try:
                # extract the subdataset
                arcpy.ExtractSubDataset_management(infile, outname, str(layer))
                # define the projection as the MODIS Sinusoidal
                Define_MODIS_Projection(outname)
                
                if not Quiet:
                    print '{Extract_MODIS_HDF} Extracted ' + outname
            except:
                if not Quiet:
                    print '{Extract_MODIS_HDF} Failed extract '+ outname + ' from ' + infile
                failed.append(infile)
                
    if not Quiet:print '{Extract_MODIS_HDF} Finished!' 
    return(failed)

#======================================================================================
def Define_MODIS_Projection(filename):
#--------------------------------------------------------------------------------------
# Simple function to give a MODIS file a defined projection for its custom Sinusoidal
#--------------------------------------------------------------------------------------

    # st up arcpy
    import arcpy
    arcpy.env.overwriteOutput = True
    
    # custom text for MODIS sinusoidal projection
    proj= """PROJCS["Sinusoidal",
                GEOGCS["GCS_Undefined",
                    DATUM["D_Undefined",
                        SPHEROID["User_Defined_Spheroid",6371007.181,0.0]],
                    PRIMEM["Greenwich",0.0],
                    UNIT["Degree",0.017453292519943295]],
                PROJECTION["Sinusoidal"],
                PARAMETER["False_Easting",0.0],
                PARAMETER["False_Northing",0.0],
                PARAMETER["Central_Meridian",0.0],
                UNIT["Meter",1.0]]"""

    arcpy.DefineProjection_management(filename,proj)

    return

#======================================================================================
def List_Files(recursive,Dir,Contains,DoesNotContain,Quiet=False):
#======================================================================================
# This function sifts through a directory and returns a list of filepaths for all files
# meeting the input criteria. Useful for discriminatory iteration or recursive searches.
# Could be used to find all tiles with a given datestring such as 'MOD11A1.A2012', or
# perhaps all Band 4 tiles from a directory containing landsat 8 data.
#
# Inputs:
#       recursive       'True' if search should search subfolders within the directory
#                       'False'if search should ignore files in subfolders.
#       Dir             The directory in which to search for files meeting the criteria
#       Contains        search criteria to limit returned file list. File names must
#                       contain parameters listed here. If no criteria exists use 'False'
#       DoesNotContain  search criteria to limit returned file list. File names must not
#                       contain parameters listed here. If no criteria exists use 'False'
#       Quiet           Set Quiet to 'True' if you don't want anything printed to screen.
#                       Defaults to 'False' if left blank.
# Outputs:
#       filelist        An array of full filepaths meeting the criteria.
#
# Example Usage:
#       import ND
#       filelist=ND.List_Files(True,r'E:\Landsat7','B1',['gz','xml','ovr'])
#
#       The above statement will find all the Band 1 tifs in a landsat data directory
#       without including the associated metadata and uncompressed gz files.
#       "filelist" variable will contain full filepaths to all files found.
#--------------------------------------------------------------------------------------

    # import modules and set up empty lists
    import os,glob,datetime
    filelist=[]
    templist=[]

    # ensure input directory actually exists
    if not Exists(Dir): return(False)

    # Ensure single strings are in list format for the loops below
    if Contains: Contains = Enforce_List(Contains)
    if DoesNotContain:
        DoesNotContain = Enforce_List(DoesNotContain)
        DoesNotContain.append('sr.lock')    # make sure lock files don't get counted
    else:
        DoesNotContain=['sr.lock']          # make sure lock files don't get counted
    
    # use os.walk commands to search through whole directory if recursive
    if recursive:
        for root,dirs,files in os.walk(Dir):
            for basename in files:
                filename = os.path.join(root,basename)
                
                # if both conditions exist, add items which meet Contains criteria
                if Contains and DoesNotContain:
                    for i in Contains:
                        if i in basename:
                            templist.append(filename)
                    # if the entire array of 'Contains' terms were found, add to list
                    if len(templist)==len(Contains):
                        filelist.append(filename)
                    templist=[]
                        
                    # remove items which do not meet the DoesNotcontain criteria
                    for j in DoesNotContain:
                        if j in basename:
                            try: filelist.remove(filename)
                            except: pass
                                    
                # If both conditions do not exist (one is false)                        
                else:
                    # determine if a file is good. if it is, add it to the list.
                    if Contains:
                        for i in Contains:
                            if i in basename:
                                templist.append(filename)
                        # if the entire array of 'Contains' terms were found, add to list
                        if len(templist)==len(Contains):
                            filelist.append(filename)
                        templist=[]

                    # add all files to the list, then remove the bad ones.        
                    if DoesNotContain:
                        filelist.append(filename)
                        for j in DoesNotContain:
                            if j in basename:
                                try: filelist.remove(filename)
                                except: pass
                                        
                # if neither condition exists
                    if not Contains and not DoesNotContain:
                        filelist.append(filename)

    # use a simple listdir if file list if recursive is False
    else:
        # add files that meet all contain critiera
        for basename in os.listdir(Dir):
            filename= os.path.join(Dir,basename)
            if Contains:
                for i in Contains:
                    if i in basename:
                        templist.append(filename)
                        
                # if the entire array of 'Contains' terms were found, add to list
                if len(templist)==len(Contains):
                    filelist.append(filename)
                templist=[]
                
            # Remove any files from the filelist that fail DoesNotContain criteria
            if DoesNotContain:
                for j in DoesNotContain:
                    if j in basename:
                        try: filelist.remove(filename)
                        except: pass
                        

    # Print a quick status summary before finishing up if Quiet is False
    if not Quiet:
        print '{List_Files} Files found which meet all input criteria: ' + str(len(filelist))
        print '{List_Files} finished!'
    
    return(filelist)
#======================================================================================
def Grab_Data_Info(filepath,CustGroupings=False,Quiet=False):
#======================================================================================
# This function simply extracts relevant sorting information from a MODIS or Landsat
# filepath of any type or product and returns object properties relevant to that data.
# it will be expanded to include additional data products in the future.
#
# Inputs:
#       filepath        full or partial filepath to any modis product tile
#       CustGroupings   User defined sorting by julian days of specified bin widths.
#                       input of 5 for example will gorup January 1,2,3,4,5 in the first bin
#                       and january 6,7,8,9,10 in the second bin, etc.
#       Quiet           Set Quiet to 'True' if you don't want anything printed to screen.
#                       Defaults to 'False' if left blank.
# Outputs:
#       info            on object containing the attributes (product, year, day, tile)
#                       retrieve these values by calling "info.product", "info.year" etc.
#
# Attributes by data type:
#       All             type,year,j_day,month,day,season,CustGroupings,suffix
#
#       MODIS           product,tile
#       Landsat         sensor,satellite,WRSpath,WRSrow,groundstationID,Version,band
#
# Attribute descriptions:
#       type            NASA data type, for exmaple 'MODIS' and 'Landsat'
#       year            four digit year the data was taken
#       j_day           julian day 1 to 365 or 366 for leap years
#       month           three character month abbreviation
#       day             day of the month
#       season          'Winter','Spring','Summer', or 'Autumn'
#       CustGroupings   bin number of data according to custom group value. sorted by
#                       julian day
#       suffix          Any additional trailing information in the filename. used to find
#                       details about special
#
#       product         usually a level 3 data product from sensor such as MOD11A1
#       tile            MODIS sinusoidal tile h##v## format
#
#       sensor          Landsat sensor
#       satellite       usually 5,7, or 8 for the landsat satellite
#       WRSpath         Landsat path designator
#       WRSrow          Landsat row designator
#       groundstationID ground station which recieved the data download fromt he satellite
#       Version         Version of landsat data product
#       band            band of landsat data product, usually 1 through 10 or 11.      
#--------------------------------------------------------------------------------------

    #import modules
    import os
    import datetime
    
    # pull the filename and path apart 
    path,name=os.path.split(filepath)
    
    # create an object class and the info object
    class Object(object):pass
    info = Object()

    # figure out what kind of data these files are. 
    data_type = Identify(name)
    
    # if data looks like MODIS data
    if data_type == 'MODIS':
        params=['product','year','j_day','tile','type','suffix']
        string=[name[0:7],name[9:13],name[13:16],name[17:23],'MODIS',name[25:]]
        for i in range(len(params)):
            setattr(info,params[i],string[i])
            
    # if data looks like Landsat data
    elif data_type =='Landsat':
        params=['sensor','satellite','WRSpath','WRSrow','year','j_day','groundstationID',
                'Version','band','type','suffix']
        name=name.split('.')[0] #remove file extension
        string=[name[1],name[2],name[3:6],name[6:9],name[9:13],name[13:16],name[16:19],
                name[19:21],name[23:].split('_')[0],'Landsat','_'.join(name[23:].split('_')[1:])]
        for i in range(len(params)):
            setattr(info,params[i],string[i])

    # if data looks like TRMM data
    elif data_type == 'TRMM':
        print '{Grab_Data_Info} no support for TRMM data yet! you should add it!'
        return(False)

    # if data looks like AMSR_E data
    elif data_type == 'AMSR_E':
        print '{Grab_Data_Info} no support for AMSR_E data yet! you should add it!'
        return(False)

    # if data looks like ASTER data
    elif data_type == 'ASTER':
        print '{Grab_Data_Info} no support for ASTER data yet! you should add it!'
        return(False)

    # if data looks like AIRS data
    elif data_type == 'AIRS':
        print '{Grab_Data_Info} no support for AIRS data yet! you should add it!'
        return(False)

    # if data doesnt look like anything!
    else:
        print 'Data type for file ['+name+'] could not be identified as any supported type'
        print 'improve this function by adding info for this datatype!'
        
        return(False)
    # ................................................................................

    # fill in date format values and custom grouping and season information based on julian day
    
    # many files are named according to julian day. we want the date info for these files
    try:
        tempinfo= datetime.datetime(int(info.year),1,1)+datetime.timedelta(int(int(info.j_day)-1))
        info.month  = tempinfo.strftime('%b')
        info.day    = tempinfo.day
    # some files are named according to date. we want the julian day info for these files
    except:
        fmt = '%Y.%m.%d'
        tempinfo= datetime.datetime.strptime('.'.join([info.year,info.month,info.day]),fmt)
        info.j_day = tempinfo.strftime('%a')

    # fill in the seasons by checking the value of julian day
    if int(info.j_day) <=78 or int(info.j_day) >=355:
        info.season='Winter'
    elif int(info.j_day) <=171:
        info.season='Spring'
    elif int(info.j_day)<=265:
        info.season='Summer'
    elif int(info.j_day)<=354:
        info.season='Autumn'
        
    # bin by julian day if integer group width was input
    if CustGroupings:
        CustGroupings=Enforce_List(CustGroupings)
        for grouping in CustGroupings:
            if type(grouping)==int:
                groupname='custom' + str(grouping)
                setattr(info,groupname,1+(int(info.j_day)-1)/(grouping))
            else:
                print('{Grab_Data_Info} invalid custom grouping entered!')
                print('{Grab_Data_Info} [CustGrouping] must be one or more integers in a list')

    # make sure the filepath input actually leads to a real file, then give user the info
    if Exists(filepath):
        if not Quiet:
            print '{Grab_Data_Info} '+ info.type + ' File ['+ name +'] has attributes ',vars(info)
        return(info)
    else: return(False)

#======================================================================================
def Identify(name):
#======================================================================================
# function to examine a filename and compare it against known file naming conventions
#
# Inputs:
#   filename    any filename of a file which is suspected to be a satellite data product
#
# Outputs:
#   data_type   If the file is found to be of a specific data type, output a string
#               designating that type. The options are as follows, with urls for reference                          
#
# data_types:
#       MODIS       https://lpdaac.usgs.gov/products/modis_products_table/modis_overview
#       Landsat     http://landsat.usgs.gov/naming_conventions_scene_identifiers.php
#       TRMM        http://disc.sci.gsfc.nasa.gov/precipitation/documentation/TRMM_README/
#       AMSR_E      http://nsidc.org/data/docs/daac/ae_ocean_products.gd.html
#       ASTER       http://mapaspects.org/article/matching-aster-granule-id-filenames
#       AIRS        http://csyotc.cira.colostate.edu/documentation/AIRS/AIRS_V5_Data_Product_Description.pdf
#       False       if no other types appear to be correct.  
#--------------------------------------------------------------------------------------

    if  any( x==name[0:2] for x in ['LC','LO','LT','LE','LM']):
        return('Landsat')
    elif any( x==name[0:3] for x in ['MCD','MOD','MYD']):
        return('MODIS')
    elif any( x==name[0:4] for x in ['3A11','3A12','3A25','3A26','3B31','3A46','3B42','3B43']):
        return('TRMM')
    elif name[0:3]=='GPM':
        return('GPM')
    elif name[0:6]=='AMSR_E':
        return('AMSR_E')
    elif name[0:3]=='AST':
        return('ASTER')
    elif name[0:3]=='AIR':
        return('AIRS')
    
#--------------------------------------------------------------------------------------
def Exists(location):

    # import modules
    import os
    
    # if the object is neither a file or a location, return False.
    if not os.path.exists(location) and not os.path.isfile(location):
        print '{Exists} '+location + ' is not a valid file or folder!'
        return(False)
    
    #otherwise, return True.
    return(True)

def Enforce_List(item):

    if not isinstance(item,list) and item:
        return([item])
    
    elif isinstance(item,bool):
        print '{Enforce_List} Cannot enforce a bool to be list! at least one list type input is invalid!'
        return(False)
    
    else:
        return(item)
    
def Check_Spatial_Extension():

    import arcpy
    if arcpy.CheckExtension('Spatial')=='Available':
        arcpy.CheckOutExtension('Spatial')
        from arcpy.sa import *
        from arcpy import env
        arcpy.env.overwriteOutput = True
    else:
        print 'You do not have the spatial analyst extension!'
    return
#--------------------------------------------------------------------------------------
def Project_Filelist(filelist,reference_file,outdir=False,resampling_type=False,cell_size=False,Quiet=False):

    import arcpy,os

    # sanitize inputs and create directories
    Exists(reference_file)
    filelist = Enforce_List(filelist)
    if not os.path.isdir(outdir):
        os.makedirs(outdir)

    # grab data about the spatial reference of the reference file. (prj or otherwise)
    if reference_file[-3:]=='prj':
        Spatial_Reference = arcpy.SpatialReference(Spatial_Reference)
    else:
        Spatial_Reference  =arcpy.Describe(reference_file).spatialReference
        
    # determine wether coordinate system is projected or geographic and print info
    if Spatial_Reference.type=='Projected':
        if not Quiet:
            print('{Project_Filelist} Found ['+ Spatial_Reference.PCSName +
                    '] Projected coordinate system')
    else:
        if not Quiet:
            print('{Project_Filelist} Found ['+ Spatial_Reference.GCSName +
                    '] Geographic coordinate system')

    # begin projecting each file in the filelist
    for filename in filelist:

        # grab info for the output name
        head,tail=os.path.split(filename)

        # set the workspace to be right where the files are.
        # arcpy.env.workspace = head
        
        # removes the file extention from the end without bothering other '.' characters
        ext=tail.split('.')[-1]
        tail='.'.join(tail.split('.')[:-1])

        # assemble the output filepath, with user input 'outdir' if applicable
        if outdir: outname=os.path.join(outdir,tail + '_p.'+ext)
        else: outname=os.path.join(head,tail + '_p.'+ext)
    
        # Perform the projection!...................................................
        try:
            # use ProjectRaster_management for files with extensions listed here
            if any( ext==filename[-3:] for ext in ['bil','bip','bmp','bsq','dat',
                    'gif','img','jpg','jp2','png','tif']):
                if resampling_type:
                    if cell_size:
                        arcpy.ProjectRaster_management(filename,outname,Spatial_Reference,
                                resampling_type,cell_size)
                    else:
                        arcpy.ProjectRaster_management(filename,outname,Spatial_Reference,
                                resampling_type)
                else:
                    arcpy.ProjectRaster_management(filename,outname,Spatial_Reference)
                    
            # otherwise, use Project_management for featureclasses and featurelayers
            else:
                arcpy.Project_management(filename,outname,Spatial_Reference)

            # print a status update    
            if not Quiet: print '{Project_Filelist} Wrote projected file to ' + outname
            
        except:
            if not Quiet: print '{Project_Filelist} Failed to project file ' +filename
    
    return(Spatial_Reference)
