%==========================================================================
%      Assembles all SRM inputs to one master file for easy inspection
%==========================================================================
%
%   function usage:
%       []=CreateMaster(root,Basin,year)
%
%   Variable Definitions:
%       root    = Directory where NASA_DEVELOP package is locally saved
%       Basin   = name of folder containing basin for analysis
%       year    = year to process 
%
%   MORE DESCRIPTION NEEDED, perhaps put custom error messages to say where
%   the problems exist.
%
%   NASA DEVELOP program 
%   contact: Jeff.Ely.08@gmail.com
%==========================================================================

function []=CreateMaster(root,Basin,year)

%==========================================================================
%                           	Code
%==========================================================================

disp('Status: Creating Master file!');

% delete any existing output file
OutName= strcat(root,'\Datos\Cuencas\',Basin,'\Datos_Intermedia\Master',year,'.xls');
if exist(OutName)
    delete(OutName)
end
  
year =num2str(year);
dir=strcat(root,'\Datos\Cuencas\',Basin,'\Datos_Intermedia');
BasinParameters=strcat(root,'\Datos\Cuencas\',Basin,'\Parametros');

% assemble data files

    % snow comes crom nasa data and should always exist at this locatoin
    if exist(strcat(dir,'\DailySnowCover',year,'.xls'),'file')
        Snow= xlsread(strcat(dir,'\DailySnowCover',year,'.xls'));
    else
        disp('Snow cover data has not been properly proccessed!');
        error(strcat('confirm that file ',dir,'\DailySnowCover',year,'.xls',' exists'));
    end
    
    % load up temperature data from DGA processed data if it exists
    if exist(strcat(dir,'\AverageTemp',year,'.xls'),'file')
        Temp= xlsread(strcat(dir,'\AverageTemp',year,'.xls'));
    else
        Temp(:,1:2)=zeros(366,2);
        warning('No DGA formated temperature data found! using zeros!');
    end
    
    % load up discharge data from DGA processed data if it exists
    if exist(strcat(dir,'\TotalDischarge',year,'.xls'),'file')
        Discharge=  xlsread(strcat(dir,'\TotalDischarge',year,'.xls'));
    else
        warning('No DGA formated Flow data found! using zeros!');
        Discharge(:,1:2)= zeros(366,2);
    end
    
    % load precipitation data from DGA processed data if it exists
    if exist(strcat(dir,'\AveragePrecip',year,'.xls'),'file');
        Precip = xlsread(strcat(dir,'\AveragePrecip',year,'.xls'));
    else
        warning('No DGA formated Precipitation data found! using zeros!');
        Precip(:,1:2)=zeros(366,2);
    end
    
    %load precipitation from TRMM dbf file if it exists
    if exist(strcat(dir,'\TRMM\TRMM_Precip',year,'.dbf'),'file')
        temp= xlsread(strcat(dir,'\TRMM\TRMM_Precip',year,'.dbf'));
        if year/4 ==0
            PrecipNASA(1:366,1)=1:366;
            PrecipNASA(1:366,2)=0;
        else
            PrecipNASA(1:365,1)=1:365;
            PrecipNASA(1:365,2)=0;
        end
        PrecipNASA(1:size(temp,1),1)=temp(:,1);
        PrecipNASA(1:size(temp,1),2)=temp(:,7);
    elseif exist(strcat(dir,'\GPM_Precip',year,'.xls'),'file')
        PrecipNASA= xlsread(strcat(dir,'\GPM_Precip',year,'.xls'));
        disp('Status: GPM data found and used!');
    elseif exist(strcat(dir,'\TRMM_Precip',year,'.xls'),'file')
        PrecipNASA= xlsread(strcat(dir,'\TRMM_Precip',year,'.xls'));
    else
        warning('No NASA precipitation data found! using zeros!');
        PrecipNASA(:,1:2)=zeros(366,2);
    end
        
    PrecipNASA= PrecipNASA.*2.4; %converted to cm/day from mm/hour

% assemble basin parameter files
    MeltF       =xlsread(strcat(BasinParameters,'\Melt_Factor.xls'));
    RCsnow      =xlsread(strcat(BasinParameters,'\RC_snow.xls'));
    RCPstations =xlsread(strcat(BasinParameters,'\RC_Pstations.xls'));
    RCPnasa     =xlsread(strcat(BasinParameters,'\RC_Pnasa.xls'));
    Tlapse      =xlsread(strcat(BasinParameters,'\Temperature_Lapse.xls'));
    Recess      =xlsread(strcat(BasinParameters,'\RecessionCoeff.xls'));
   
% Build the master matrix for saving to the master input file.
    
    % make some accomodations for leap years
        if rem(str2num(year),4)==0
            range=1:366; % for leap years
        else
            range=1:365; % for not leap years
        end

    % fill initial matrix with zeros, to help reduce NaN values
        Master = zeros(range(end),26);

        Master(range,1:2)=Discharge(range,1:2);
        Master(range,3)= Precip(range,2)./10;
        Master(range,4)=PrecipNASA(range,2);
        Master(range,5)= Temp(range,2);
        Master(range,6:20)=Snow(range,2:16);
        Master(range,21)=MeltF(range);
        Master(range,22)=RCsnow(range);
        Master(range,23)=RCPstations(range);
        Master(range,24)=RCPnasa(range);
        Master(range,25)=Tlapse(range);
        Master(range,26:27)=Recess(range,1:2);
    
    % ensure no NaN values still exist
        Master(isnan(Master)) = 0 ;    

%==========================================================================
%                       Write master file with Headers
%========================================================================== 

    Headers={'Day','Measured Discharge' ,'Station Precip','NASA Precip',...
        'Avg Temp' ,'Zone1', 'Zone2' ,'Zone3' ,'Zone4','Zone5',...
        'Zone6' ,'Zone7', 'Zone8' ,'Zone9','Zone10' ,'Zone11',...
        'Zone12', 'Zone13', 'Zone14', 'Zone15','DegDay' ,'RCsnow',...
        'RC_Pstations', 'RC_Pnasa','Tlapse', 'Recess_X','Recess_Y'};
    
    xlswrite(strcat(root,'\Datos\Cuencas\',Basin,....
        '\Datos_Intermedia\Master',year,'.xls'),Headers,'Sheet1','A1');
    
    xlswrite(strcat(root,'\Datos\Cuencas\',Basin,...
        '\Datos_Intermedia\Master',year,'.xls'),Master,'Sheet1','A2');

% Dsiplay progress
    disp('Status: Master File Created! You can make manual changes to this');
    disp(strcat('file stored at',strcat(root,'\Datos\Cuencas\',Basin,....
        '\Datos_Intermedia\Master',year,'.xls')));
    
end