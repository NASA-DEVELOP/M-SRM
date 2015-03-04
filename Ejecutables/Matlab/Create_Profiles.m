%==========================================================================
%           Script to create snowcover and temperature profiles
%==========================================================================
%
%   Script should be used when characterizing typical snowcover and
%   temperature profiles for a basin. This requires snow cover analysis and
%   Temperature records to exist in default formats for as many years as
%   possible. complete MODIS data is available from 2001 forward, but the
%   in-situ data from the DGA download site is the typical limiting factor
%   on normalized profiles.
%
%   Usage:
%       []=Create_Profiles(root,Basin,Years)
%
%   Variable Definitions:
%       root    = Directory where NASA_DEVELOP package is locally saved
%       Basin   = name of folder containing basin for analysis
%       Years   = Array of years to include in average
%
%   NASA DEVELOP program 
%   contact: Jeff.Ely.08@gmail.com
%   version: 3/17/2014 
%==========================================================================

function []=Create_Profiles(root,Basin,Years)

%==========================================================================
%                        Create filepaths and variables
%==========================================================================

% concatenate common path to use later
    path = strcat(root,'\Datos\Cuencas\',Basin,'\Datos_Intermedia\');
    
% Create empty variables and start indexes 
    index=1;   
    Snow=zeros(366,32,length(Years));
    Temp=zeros(366,2,length(Years));
    PrecipIS=zeros(366,2,length(Years));
    PrecipNASA=zeros(366,2,length(Years));
 
%==========================================================================
%                   Load and process data for selected years
%========================================================================== 
for year=Years

   if rem(year,4)==0
        range=1:366; % for leap years
   else
        range=1:365; % for not leap years
   end
   
   year =num2str(year);
%Snowcover with erroneous >1 values removed
    temp= xlsread(strcat(path,'DailySnowCover',year,'.xls'));
    temp(temp>=1)=1; Snow(range,:,index)=temp;
    
% Temperature and precip from in situe temperature and precipitation.
   Temp(range,:,index)=xlsread(strcat(path,'AverageTemp',year,'.xls'));
   PrecipIS(range,:,index)=xlsread(strcat(path,'AveragePrecip',year,'.xls'));
   
%load precipitation from TRMM dbf file if it exists
    if exist(strcat(path,'\TRMM\TRMM_Precip',year,'.dbf'),'file')
        PrecipNASA(range,:,index)= xlsread(strcat(path,'\TRMM\TRMM_Precip',year,'.dbf'),...
            strcat('F2:G',num2str(max(range)+1)));
    elseif exist(strcat(path,'\GPM_Precip',year,'.xls'),'file')
        PrecipNASA(range,:,index)= xlsread(strcat(dir,'\GPM_Precip',year,'.xls'));
        disp('Status: GPM data found and used!');
    elseif exist(strcat(path,'\TRMM_Precip',year,'.xls'),'file')
        PrecipNASA= xlsread(strcat(dir,'\TRMM_Precip',year,'.xls'));
    else
        disp('NO TRMM data found!');
        PrecipNASA(range,:,index)=zeros(366,2);
    end

   fprintf('Create_Profiles: Loaded year %4.0f \n',str2num(year));
   index=index+1;
end

% average snow statistics across the range of years.
    for i = 1:366
        for j = 2:size(Snow,2)       
            MeanSnow(i,j)= mean(Snow(i,j,:));
        end
    end
    
    for j = 2:size(Snow,2)
        MeanSnow(:,j)=smooth(MeanSnow(:,j),15);
    end
    MeanSnow(:,1)=1:length(MeanSnow);

% average temp statistics across the range of years.
    for i = 1:366
        for j = 2:size(Temp,2)       
            MeanTemp(i,j)= mean(Temp(i,j,:));
        end
    end
    
    for j=2:size(Temp,2)
        MeanTemp(:,j)=smooth(MeanTemp(:,j),7);
    end
    MeanTemp(:,1)=1:length(MeanTemp);

% average IN-SITU precipitation statistics across the range of years.
    for i = 1:366
        for j = 2:size(PrecipIS,2)       
            MeanPrecipIS(i,j)= mean(PrecipIS(i,j,:));
        end
    end
    
    for j=2:size(PrecipIS,2)
        MeanPrecipIS(:,j)=smooth(MeanPrecipIS(:,j),7);
    end    
    MeanPrecipIS(:,1)=1:length(MeanPrecipIS);
    
% average NASA precipitation statistics across range of years
    for i = 1:366
        for j = 2:size(PrecipIS,2)       
            MeanPrecipNASA(i,j)= mean(PrecipNASA(i,j,:));
        end
    end
    
    for j=2:size(PrecipNASA,2)
        MeanPrecipNASA(:,j)=smooth(MeanPrecipNASA(:,j),7);
    end    
    MeanPrecipNASA(:,1)=1:length(MeanPrecipNASA);

%==========================================================================
%                                 Create output
%==========================================================================

path = strcat(root,'\Datos\Cuencas\',Basin,'\Parametros\');

xlswrite(strcat(path,'SCA_Profile.xls'),MeanSnow);
xlswrite(strcat(path,'Temperature_Profile.xls'),MeanTemp);
xlswrite(strcat(path,'PrecipIS_Profile.xls'),MeanPrecipIS);
xlswrite(strcat(path,'PrecipNASA_Profile.xls'),MeanPrecipNASA);

disp('Create_Profiles: Profiles created!');
end
%==========================================================================