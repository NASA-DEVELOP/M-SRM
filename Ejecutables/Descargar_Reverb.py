#====================================================================================
#                               Descargar Desde el Código de FTP
#                                   Download from FTP script
#------------------------------------------------------------------------------------
#
#(Español)
#   Este código introduce un archivo (. Txt) que contiene una lista de descarga 
#   enlaces como salida de 'Reverb Echo'. Para obtener información sobre cómo usar
#   Reverb, consultar el sitio web en [http://reverb.echo.nasa.gov/]
#
#(English)
#   This script inputs a (.txt) file containing a list of download
#   links as output by Reverb Echo. For information on how to use Reverb,
#   consult the website at [http://reverb.echo.nasa.gov/]
#
# Descripciones de entrada
#   ftptext = full path to text file downloaded from reverb
#               (data found by searching for product "MOD10A1")
#   output  = directory for files to be stored when downloaded
#
# Valores de entrada ejemplo
#   ftptext = 'C:/Users/jwely/NASA_DEVELOP_TESTBED/Datos/NASA_Datos/MODIS_2011.txt'
#   output  = 'C:/Users/jwely/NASA_DEVELOP_TESTBED/Datos/NASA_Datos/MODIS/2011'
#
#
#===================================================================================
#                       valores de entrada de usuario
#                            (User Input values)
#-----------------------------------------------------------------------------------

ftptext = r'C:\Users\jwely\Desktop\Chile\NASA_DEVELOP_SRM\Datos\NASA_Datos\MODIS\2014\data_url_script_2014-10-08_103433.txt'
outdir  = r'C:\Users\jwely\Desktop\Chile\NASA_DEVELOP_SRM\Datos\NASA_Datos\MODIS\2014'

#======================================================================================

def Enforce_List(item):
    if not isinstance(item,list) and item:
        item=[item]

    return(item)
#======================================================================================
def Download_From_Urls(urls,filetypes,outdir,Quiet=False):
#--------------------------------------------------------------------------------------
# This script downloads a list of files and places it in the output directory. It was
# built to be nested within "Download_List_of_Files" to allow loops to continuously retry
# failed files until they are successful or a retry limit is reached.
#
# Inputs:
#       urls        array of urls, probably as read from a text file
#       outdir      folder where files are to be placed after download
#       Quiet       Set Quiet to 'True' if you don't want anything printed to screen.
#                   Defaults to 'False' if left blank.  
#
# Outputs:
#       failed      A list of all urls for which downloads have failed
#--------------------------------------------------------------------------------------

    # import modules
    import urllib
    import os

    # fix output directory slash convention
    outdir=outdir.replace('\\','/')

    # creates output folder at desired path if it doesn't already exist
    if not os.path.exists(outdir):
        os.makedirs(outdir)

    # enforce single entries to be a list for subsequent iteration purposes
    urls=Enforce_List(urls)

    # empty list to track the number of failed downloads
    failed=[]

    for site in urls:
        url = site.rstrip()
        sub = url.split("/")
        leng = len(sub)
        name = sub[leng-1]
        
        #Try to download only files of specefied filetype
        for filetype in filetypes:
            if filetype in sub[leng-1]:
                try:
                    writefile=open(outdir + '/' + sub[leng-1],'wb')
                    page= urllib.urlopen(url).read()
                    writefile.write(page)
                    writefile.close()
                    if not Quiet:
                        print(sub[leng-1]+ "  is downloaded")

                # add to the failcount if the download is unsuccessful
                except:
                    failed.append(url)

    return (failed)
    
#===================================================================================
def Download_List_of_Files(ftptext,filetypes,outdir,Quiet=False):
#--------------------------------------------------------------------------------------
# This script reads a text file with urls such as those output from ECHO REVERB
# and outputs them to an output directory. It will retry failed links 10 times before
# giving up and outputing a warning to the user.
#
# Inputs:
#       ftptext     array of txt files ordered from reverb containing ftp links
#       filetype    file extension of the desired files, usually '.hdf' for MODIS
#       outdir      folder where files are to be placed after download
#       Quiet       Set Quiet to 'True' if you don't want anything printed to screen.
#                   Defaults to 'False' if left blank.
#
# Outputs:
#       failed      the number of downloads in a given file that have failed
#--------------------------------------------------------------------------------------

    # import modules
    import urllib
    import os

    # force inputs to take list format
    filetypes=Enforce_List(filetypes)
    
    ftp = open(ftptext,'r')
    sites =ftp.readlines()
    failed=Download_From_Urls(sites,filetypes,outdir)
    for i in range(1,10):
        if len(failed)>0:
            print 'Retry number : '+ str(i)
            failed=Download_From_Urls(failed,filetypes,outdir)

    if not Quiet:
        if len(failed)>0:
            print 'Files at the following URLs have failed 10 download attempts:'
            for i in failed:
                print i
        else:
            print 'All downloads have been successful!'

    return (failed)
        
#===================================================================================
Download_List_of_Files(ftptext,'hdf',outdir,False)
print 'Finished downloading all files from Reverb!'

# Finished up in November 2014: Jeff Ely
