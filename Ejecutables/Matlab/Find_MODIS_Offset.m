%Find displacement between 2 simple grayscale images using cross
%correlation
function [offrow,offcol]=Find_MODIS_Offset(Root,Basin,year)
    pad=300;

% fetch Elevation zone tiff
    ElevationsPath=strcat(Root,'\Datos\Cuencas\',Basin,'\Parametros\Elev_Zones.tif');
    tempE=imread(ElevationsPath);
    E=zeros(size(tempE,1)+pad,size(tempE,2)+pad)+255;
    E((pad/2+1):(end-pad/2),(pad/2+1):(end-(pad/2)))=tempE;

% fetch a sample image from the desired year of MODIS data.
    cd(strcat(Root,'\Datos\Cuencas\',Basin,'\Datos_Intermedia\MODIS\',num2str(year)));
    d=dir('*.tif');
    d(1).name;
    tempM=imread(d(1).name);
    M=zeros(size(tempE,1)+pad,size(tempE,2)+pad)+255;
    M((pad/2+1):(pad/2+size(tempM,1)),(pad/2+1):(pad/2+size(tempM,2)))=tempM;

% set all pixels with data equal to 1 to isolate shapes instead of lumance
    E(E~=255)=1;
    M(M~=255)=1;

    cd(strcat(Root,'\Ejecutables\Matlab'));
% perform cross correlation on the images
    [output ~]= Findoffset(fft2(E),fft2(M),1);
    offrow=output(3);
    offcol=output(4);

% set up new matrix for offset image that is aligned.
    Mnew=tempM;
    Mnew(Mnew~=255)=1;
    if offrow>=0
        Mnew=[zeros(offrow,size(Mnew,2))+255;Mnew];
    else
        Mnew(1:abs(offrow),:)=[];
    end

    if offcol>=0
        Mnew=[zeros(size(Mnew,1),offcol)+255 Mnew];
    else
        Mnew(:,1:abs(offcol))=[];
    end

end


