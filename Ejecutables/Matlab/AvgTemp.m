%==========================================================================
%                       Averages Temperature values
%==========================================================================
%
%   function usage:
%       []=AvgTemp(root,Basin,year)
%
%   Variable Definitions:
%       root    = Directory where NASA_DEVELOP package is locally saved
%       Basin   = name of folder containing basin for analysis
%       year    = year to process 
%
%   This script is designed to format temperature data in the format
%   used by [www.dga.cl] on data downloads. These files must be MANUALLY
%   CHECKED for empty data cells, and 0 must be placed in these cells.A 
%   maximum of 10 stations can be exported at a time and stored in a 
%   single excel file, so 10 stations is the maximum number of stations 
%   that may be averaged together. 
%
%   files must be in format "Temperaturas Diarias Extremas[YEAR]" and 
%   stored in the correct "DGA_Descargas" folder. 
%
%   for example "Temperaturas Diarias Extremas2011.xls"
%
%   Output file is stored in the "Datos_Intermedia" folder under the basin
%   being processed
%
%   NASA DEVELOP program 
%   contact: Jeff.Ely.08@gmail.com
%==========================================================================

function []=AvgTemp(root,Basin,year)

%==========================================================================
%                               Code
%==========================================================================
fprintf('Status: Averaging Temperature data for year %4.0f \n',year);
year=num2str(year);

% Find the number of tabs in xls document.
[~,NumStations]=xlsfinfo(strcat(root,'\Datos\Cuencas\',Basin,...
        '\DGA_Descargas\Temperaturas Diarias Extremas',year,'.xls'));
    
% compile temperature values into a matrix, one column for each station
    for i=1:length(NumStations)
        
        if year/4==0
            Temp(1:366,i)=0;
        else
            Temp(1:365,i)=0;
        end

        In=xlsread(strcat(root,...
            '\Datos\Cuencas\',Basin,'\DGA_Descargas\Temperaturas Diarias Extremas',year,'.xls'),i);
        [A]=find(isnan(In(:,1))==1);

        % specifically for formating those nasty DGA files.
        Data=[In(14:(A(14)-1),2),In(14:(A(14)-1),4);...
            In(14:(A(14)-1),5),In(14:(A(14)-1),6);...
            In(14:(A(14)-1),7),In(14:(A(14)-1),8);...
            In(14:(A(14)-1),10),In(14:(A(14)-1),11);...
            In(14:(A(14)-1),12),In(14:(A(14)-1),13);...
            In(14:(A(14)-1),14),In(14:(A(14)-1),15);
            In((A(end)+1):end,2),In((A(end)+1):end,4);...
            In((A(end)+1):end,5),In((A(end)+1):end,6);...
            In((A(end)+1):end,7),In((A(end)+1):end,8);...
            In((A(end)+1):end,10),In((A(end)+1):end,11);...
            In((A(end)+1):end,12),In((A(end)+1):end,13);...
            In((A(end)+1):end,14),In((A(end)+1):end,15)];

        % remove null values. and string the columns of unequal length 
        % into a single column. (Sloppy)
        Data(isnan(Data))=-100; 
        q=Data(:,1)==-100;
        A=Data(:,1); B=Data(:,2);
        A=A(~q); B=B(~q);
        clear Data
        Data(:,1)=A; Data(:,2)=B;

        for z=1:size(Data,1)
            Data(z,3)=(Data(z,1)+Data(z,2))/2;
        end

        Temp(1:size(Data,1),i)=Data(1:end,3);

    end

% averages across the temperature stations to produce one Temp value
    for z=1:size(Temp,1)
        Avg(z,2)=mean(Temp(z,:));
        Avg(z,1)=z;
    end
    
% Create output

    xlswrite(strcat(root,'\Datos\Cuencas\',Basin,...
        '\Datos_Intermedia\AverageTemp',year,'.xls'),Avg,'Sheet1');

    disp('Status: Temperature data formated and saved!');
    
end
