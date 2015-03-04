%==========================================================================
%             Creates a Hypsometric Profile for 1 Basin
%==========================================================================
%
%   function usage:
%       []=Hypso(root,Basin)
%
%   Variable Definitions:
%       root    = Directory where NASA_DEVELOP package is locally root
%       Basin   = name of folder containing basin for analysis
%       Area    = Total area of the basin shapefil used in ArcSWAT.
%
%   This script is designed to work with output TXT file from arcswat to
%   characterize a basins elevation profile. Arcswat rounds to the nearest
%   hundredth, so basins whos area is less than .02% of the total basin
%   area will be lost entirely, but are not expected to dramatically
%   influence the output.
%
%   Files must have the name Area_Elevation.txt and stored in the basin 
%   parameters folder. Output file is stored in the same folder as the 
%   input file, under the parameters folder for that basin.
%
%   NASA DEVELOP program 
%   Version 3/4/2014 11:40am
%==========================================================================

function [] = Hypso(root,Basin)

%==========================================================================
%                              	Code
%==========================================================================

disp('Status: Characterizing basins elevation profile!');


% Fetch text files containing area elevation curve and Basin Meta.txt file
text =strcat(root,'\Datos\Cuencas\',Basin,'\Parametros\Area_Elevation.txt');
fid= fopen(strcat(root,'\Datos\Cuencas\',Basin,'\Meta.txt'));
meta=textscan(fid,'%s','delimiter','\n');
meta=char(meta{1}(2)); Area=str2num(meta(13:end))/1000000;



fileID = fopen(text);
C = textscan(fileID, '%s');
Arr = C{1};

%%-------------Get all the Elevation Numbers into an array here----------%

count = 1; 
for i = 41:3:(size(Arr)-3) 
   try
    Elev(count) = str2num(Arr{i}); 
    count = count+1;  
    
   catch ME
    error('MATLAB:Odeargument:InconsistentDataType', ...
    'Only one elevation report may be present in text file, check for sub-basins!')
   end
end

%-----Get all the Percent Area Below Elevation Values into Array Here-----% 

count = 1; 
for i = 42:3:(size(Arr)-3)
   try
    Below(count) = str2num(Arr{i}); 
    count = count+1; 
    
   catch ME
       error('MATLAB:Odeargument:InconsistentDataType', ...
        'Check for subbasins. Only one basin allowed per file.')
   end
end

%--------------------------Find the Zones-------------------------------%
ElevOut(1)=Elev(1);
i = 2; 
zonecount = ceil(Elev(1)/500);
for m = 2:(length(Elev)-1) 
   if Elev(m)-500 *zonecount >=0 || Elev(m)- 500 *zonecount >=0
       zonecount = zonecount +1;
       ElevOut(i) = Elev(m); 
       ElevOut(i+1) = Elev(m+1);
       BelowOut(i) = Below(m); 
       BelowOut(i+1) = Below(m); 
       i = i+2; 
   end
      ElevOut(i) = Elev(end);
      BelowOut(i) = Below(end); 
end
count=1;

for m = 1:2:(length(ElevOut)-1) 
    Zone(count) = round((ElevOut(m)/500)+1);
    count= count+1;
end
%--------------------Find the Mean Elevation in the Areas-----------------%

count = 1; 
for i = 1:2:(length(ElevOut))-1
    BelowHypso(count) = round(((BelowOut(i) + BelowOut(i+1))/2)*100)/100;
    count= count+1;
end

ElevHypso=zeros(1,15);
count = 1;
var = 1; 
for i = 1: (length(Below)-1) 
   if count <= length(BelowHypso)
    if Below(i) >= BelowHypso(count) 
        if Elev(i) >= 1+ 500*(count-1) 
         ElevHypso(var) = Elev(i); 
         var = var+1; 
         count= count+1;
        end
    end
   end
end

count = 1; 
for i = 1:2:(length(ElevOut)-1) 
    Range{count} = strcat(num2str(ElevOut(i)), '-',...
        (num2str(ElevOut(i+1))));
    count= count+1;
end    

%-----------------Make Percent Below accessible for export----------------%
TopArea=zeros(1,15);
ZoneArea=zeros(1,15);
count = 1; 
for i = 2:2:length(BelowOut)
    TopArea(count) = BelowOut(i);
    
    if count==1
        ZoneArea(count)=0.01*TopArea(count)*Area;
    else
        ZoneArea(count)=0.01*(TopArea(count)-TopArea(count-1))*Area;
    end
    
    count= count+1; 
end

%-----------------Assemble numerical output into one matrix --------------%
Out(:,1)=1:15;
Out(:,3)=ElevHypso;
Out(:,4)=TopArea;
Out(:,5)=ZoneArea;

%-------------------------------------------------------------------------%
%                            # Write to Excel #                           %
%-------------------------------------------------------------------------%
Headers = {'Zone','Range','Mean Elev','Area Below Elev','Zone Area'}; 
outpath = strcat(root,'\Datos\Cuencas\',Basin,'\Parametros\Hypso.xls');

xlswrite(outpath,Headers,'Sheet1', 'A1');
xlswrite(outpath, Out,'Sheet1', 'A2');
xlswrite(outpath, Range','Sheet1', 'B2');

fprintf('Status: Output Hypso.xls created for %s! \n',Basin);

end
