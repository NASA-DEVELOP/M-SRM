%==========================================================================
%          Totals historical Discharge values for SRM validation
%==========================================================================
%   
%   Creates total discharge files by adding all tabs located in the DGA 
%   downloaded excel file for the given year and basin
%
%   NASA DEVELOP program 
%   contact: Jeff.Ely.08@gmail.com
%==========================================================================

function []=TotalDischarge(root,Basin,year)

%==========================================================================
%                                   Code
%==========================================================================

    fprintf('Status: Calculating total discharge for year %4.0f \n',year');
    year=num2str(year);
    
% Find the number of tabs in xls document.
    [~,NumStations]=xlsfinfo(strcat(root,'\Datos\Cuencas\',Basin,...
        '\DGA_Descargas\Caudales Medios Diarios',year,'.xls'));
    
    for i=1:length(NumStations)
        
        if year/4==0
            Discharge(1:366,i)=0;
        else
            Discharge(1:365,i)=0;
        end
        
        In=xlsread(strcat(root,'\Datos\Cuencas\',Basin,...
            '\DGA_Descargas\Caudales Medios Diarios',year,'.xls'),i);

        Data=[In(13:end,2)];
        
        for j=2:11
            Data=[Data;In(13:end,2*j)];
        end
        
        Data=[Data;In(13:end,25)];
        Data(isnan(Data))=-100; Data(Data==-100)=[];
        Discharge(1:size(Data,1),i)=Data;
    end

% Sums them up
    for z=1:size(Discharge,1)
        TotDischarge(z)=sum(Discharge(z,:));
    end

    out(:,1)=1:length(TotDischarge);
    out(:,2)=TotDischarge';

    xlswrite(strcat(root,'\Datos\Cuencas\',Basin,...
        '\Datos_Intermedia\TotalDischarge',year,'.xls'),out,'Sheet1');
    
    disp('Status: Total discharge calculated!');
    
end