#====================================================================================
#                               Fetch MODIS Data.                   
#------------------------------------------------------------------------------------
#
#   This script inputs a only the year and tiles of desired MODIS snow cover data, then
#   searches an FTP server for all files meeting the criteria. The product it downloads is
#   MOD10A1. It automatically generates an output folder in the specified outdir for the
#   year being downloaded. This script does not require the user to download any text
#   files from Reverb, users wishing use the Reverb download script that was presented
#   during the Workshop in Santiago in October 2014 may use the old "descargar_reverb.py" script.
#
# Example usage:
#   year = '2014'
#   tiles=['h11v12','h11v11']
#   Package=r'C:\Users\jwely\Desktop\Chile\NASA_DEVELOP_SRM'
#
#===================================================================================
#                       valores de entrada de usuario
#                            (User Input values)
#-----------------------------------------------------------------------------------

year    = '2014'
tiles   = ['h11v12','h11v11']
package  = 'C:\Users\jwely\Desktop\Chile\NASA_DEVELOP_SRM'

#======================================================================================
import os,urllib,ftplib

def Enforce_List(item):
    if not isinstance(item,list) and item:
        item=[item]

    return(item)
        
#===================================================================================
def Fetch_MODIS(product, version, tiles, years, outdir, Quiet=False):

    # check formats
    tiles=Enforce_List(tiles)
    years=Enforce_List(years)
    years = [str(year) for year in years]
    
    # create output directories
    if not os.path.exists(os.path.join(outdir,year)):
        os.makedirs(os.path.join(outdir,year))

    # obtain the web address, protocol information, and subdirectory where
    # this type of MODIS data can be found.
    site,ftp,Dir=Find_MODIS_Product(product,version)

    # Depending on the type of connection (ftp vs http) populate the file list
    try:
        if ftp: dates=List_ftp_contents(site,Dir)
        else:   dates=List_http_contents(site)
    except: print 'Could not connect to site! check inputs!'
    
    # find just the folders within the desired year range.
    good_dates=[]
    for date in dates:
        try:
            y,m,d = date.split(".")
            if y in years:
                good_dates.append(date)
        except: pass
        
    if not Quiet: print 'Found ' + str(len(good_dates)) + ' days within year range'

    # for all folders within the desired date range,  map the subfolder contents.
    for good_date in good_dates:
        
        if ftp: files=List_ftp_contents(site,Dir+'/'+good_date)
        else:   files=List_http_contents(site+'/'+good_date)

        for afile in files:
            # only list files with desired tilenames and not preview jpgs
            if not '.jpg' in afile and not '.xml' in afile:
                for tile in tiles:
                    if tile in afile:
                        # assemble the address
                        if ftp: address='/'.join(['ftp://'+site,Dir,good_date,afile])
                        else:   address='/'.join([site,good_date,afile])
                        if not Quiet: print 'Downloading  ' + address

                        #download the file.
                        outname=os.path.join(outdir,year,afile)
                        Download_url(address,outname)

    return
#===================================================================================
def Find_MODIS_Product(product,version):
    sat_designation = product[0:3]
    prod_ID = product[3:]

    site1='http://e4ftl01.cr.usgs.gov/'
    site2='n5eil01u.ecs.nsidc.org'

    ftp=False
    Dir=False
    
    # refine the address of the desired data product
    if '10' in prod_ID:
        ftp = True
        site= site2
        
    if sat_designation=='MOD':
        if ftp: Dir = 'DP1/MOST/'+product+'.'+version
        else:   site = site1+'MOLT/'+product+'.'+version

    elif sat_designation=='MYD':
        if ftp: Dir = 'DP1/MOSA/'+product+'.'+version
        else:   site = site1+'MOLA/'+product+'.'+version
        
    elif sat_designation=='MCD':
        site = site1+'MOTA/'+product+'.'+version
        
    else:
        print 'No such MODIS product is availble for download with this script!'
    
    return site,ftp,Dir
#===================================================================================
# subfunction to download a single file
def Download_url(url,outname):
    writefile=open(outname,'wb+')
    page= urllib.urlopen(url).read()
    writefile.write(page)
    writefile.close()
    return

# subfunction for listing contents of a typical ftp download site
def List_ftp_contents(site,Dir):
    ftp=ftplib.FTP(site)
    ftp.login()
    ftp.cwd(Dir)
    print 'Connected to [' + site +'/'+ Dir + ']'
    
    rawdata = []
    ftp.dir(rawdata.append)
    files = [i.split()[-1] for i in rawdata[1:]]
    return files

# subfunction for listing contents of a typical http download site.
# primarily designed to work with server at [http://e4ftl01.cr.usgs.gov]
def List_http_contents(site):
    website=urllib.urlopen(site)
    string=website.readlines()
    print 'Connected to [' + site + ']'
    
    files=[]
    for line in string:
        try:files.append(line.replace('/','').split('"')[5])
        except: pass
    return files
#===================================================================================
Fetch_MODIS('MOD10A1','005',tiles,year,os.path.join(package,'Datos\NASA_Datos\MODIS'),False)
print 'Finished downloading all MODIS files meeting input criteria!'

# finished up in November of 2014: Jeffry Ely
