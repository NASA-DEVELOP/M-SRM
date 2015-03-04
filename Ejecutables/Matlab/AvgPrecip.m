%==========================================================================
%                       Averages Precipitation values
%==========================================================================
%
%   function usage:
%       []=AvgPrecip(root,Basin,year)
%
%   Variable Definitions:
%       root    = Directory where NASA_DEVELOP package is locally saved
%       Basin   = name of folder containing basin for analysis
%       year    = year to process 
%
%   This script is designed to format precipitation data in the format
%   used by [www.dga.cl] on data downloads. These files must be MANUALLY
%   CHECKED for empty data cells, and 0 must be placed in these cells.A 
%   maximum of 10 stations can be exported at a time and stored in a 
%   single excel file, so 10 stations is the maximum number of stations 
%   that may be averaged together. 
%
%   files must be in format "precipitaciones Diarias[YEAR]" and stored in
%   the correct "DGA_Descargas" folder. 
%
%   for example "precipitaciones Diarias2011.xls"
%
%   Output file is stored in the "Datos_Intermedia" folder under the basin
%   being processed
%
%   NASA DEVELOP program 
%   contact: Jeff.Ely.08@gmail.com
%==========================================================================

function []=AvgPrecip(root,Basin,year)

%==========================================================================
%                                   Code
%==========================================================================

fprintf('Status: Averaging precipitation data for year %4.0f \n',year);
year=num2str(year);

% Find the number of tabs in xls document.
    [~,NumStations]=xlsfinfo(strcat(root,'\Datos\Cuencas\',Basin,...
        '\DGA_Descargas\precipitaciones Diarias',year,'.xls'));

% compile precipitation values into a matrix, one column for each station
    for i=1:length(NumStations)
        
        if year/4==0
            Precip(1:366,i)=0;
        else
            Precip(1:365,i)=0;
        end
        
        In=xlsread(strcat(root,'\Datos\Cuencas\',Basin,...
            '\DGA_Descargas\precipitaciones Diarias',year,'.xls'),i);

        % specifically for formating those nasty DGA files.
        Data=[In(13:end,2);In(13:end,4);In(13:end,5);...
            In(13:end,6);In(13:end,7);In(13:end,8);In(13:end,10);...
            In(13:end,11);In(13:end,12);In(13:end,13);In(13:end,14);...
            In(13:end,15)];
        Data(isnan(Data))=-1; Data(Data==-1)=[];
        Precip(1:size(Data,1),i)=Data;

    end

% averages across the precipitation stations to produce one Precip value
    for z=1:size(Precip,1)
        Avg(z,2)=sum(Precip(z,:))./length(NumStations);
        Avg(z,1)=z;
    end

% Create output

    xlswrite(strcat(root,'\Datos\Cuencas\',Basin,...
        '\Datos_Intermedia\AveragePrecip',year,'.xls'),Avg,'Sheet1');
    
    disp('Status: Precipitation data formated and saved!');
    
end

