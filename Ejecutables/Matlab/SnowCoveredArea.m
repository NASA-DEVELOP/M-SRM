%==========================================================================
%               Calculate the Snow Covered Area for input Year
%==========================================================================
% Function inputs a Directory of Preprocessed MODIS data. This data must
% have already been run through "ReprojectAndResample" in model builder.
% The script compares each day of data with the elevation zones and the
% previous days data. All cloudy pixels are compared to yesterdays data,
% and if snow existed before that cloud rolled in, that pixel is corrected
% to snow. The output of this function is an output file in matrix form
% without a header, but whos format is listed below.
%
%   Usage:
%       [Output]=SnowCoveredArea(Root,year,Elevations)
%
%   Inputs:
%       Root        The directory where THIS FUNCTION is stored, this
%                   should end in a '/' such as "C:/path/more_path/".
%       Year        The subdirectory within Direct containing a year of 
%                   data. These folder names should be numbers like '2012'
%
%   Output xls format:
%       [Column]        [Data]
%       A               julian day
%       B-P             Snow covered area for elevation zones 1-15
%       Q-AE            cloud cover area for elevation zones 1-15
%       AF              the number of pixels which were corrected to snow   
%   
%   Column 1 is the day, column 2 is the %snowcover for the first
%   elevation zone, column 17 is the %cloud cover for the first elevation
%   zone. etc.
%       
%==========================================================================
function [Output]=SnowCoveredArea(Root,Basin,year)
%==========================================================================

ElevationsPath=strcat(Root,'\Datos\Cuencas\',Basin,'\Parametros\Elev_Zones.tif');
YearStr=num2str(year);
ModisPath=strcat(Root,'\Datos\Cuencas\',Basin,'\Datos_Intermedia\MODIS\',YearStr);
    
% ensure all images are properly aligned by finding the offset.
    disp('Status: Aligning image data!'); 
% these offset values are extremely important further down, and provide a
% fix for missing geographic reference information.
    [offrow,offcol]=Find_MODIS_Offset(Root,Basin,year);

    cd(ModisPath);
    d=dir('*.tif');
    
% define year length to accomodate leap years
    if rem(year,4)==0
        range=1:366; % for leap years
    else
        range=1:365; % for not leap years
    end
    
% delcare empty variables    
    Today = [];                     %Empty matrix for todays MODIS data
    Output(range,2:32)=0;         %Empty output matrix
    tic();                          %starts the timer
    
% declare counting variables   
    amend=zeros(length(d));         %tracks number of cloud pixel changes
    Zonecount=zeros(length(d),15);  %tracks total number of pixels in Zone
    Snow=zeros(length(d),15);       %tracks total snow pixels in Zone(i)
    Clouds=zeros(length(d),15);     %tracks total Cloud pixels in Zone(i)
    
%==========================================================================
%              Begin iterations by day and perform alignments
%==========================================================================

fprintf('\n Status: Performing SCA calculations for year (%4.0f) \n',year);

    for i = 1:length(d)
            str=d(i).name;
            DayNames{i}=str(17:19);
            
        % for January 1st, there is no yesterday (could be improved)
            if exist('Yesterday')
            %step forward one day in the future
                Yesterday=Today;
                temp=imread(d(i).name);
                
                    %apply offsets to properly align image data
                    % correct row alignment
                    if offrow>=0
                        temp=[zeros(offrow,size(temp,2))+255;temp];
                    else
                        temp(1:abs(offrow),:)=[];
                    end
                    % correct column alignment
                    if offcol>=0
                        temp=[zeros(size(temp,1),offcol)+255 temp];
                    else
                        temp(:,1:abs(offcol))=[];
                    end

                % aligns the botom left corner if image is not of correct size.
                Today=temp;
            else 
                Today=imread(d(i).name);
                % correct row alignment
                if offrow>=0
                    Today=[zeros(offrow,size(Today,2))+255;Today];
                else
                    Today(1:abs(offrow),:)=[];
                end
                % correct column alignment
                if offcol>=0
                    Today=[zeros(size(Today,1),offcol)+255 Today];
                else
                    Today(:,1:abs(offcol))=[];
                end   
                
                
                % if yesterday does not exist then create it and load up the
                % elevation file peroperly.
                Yesterday=Today;
                tempElev=imread(ElevationsPath);
                Elevations=zeros(size(Today))+255;
                Elevations(1:size(tempElev,1),1:size(tempElev,2))=tempElev;
                Elevations=Elevations(1:size(Today,1),1:size(Today,2));
              
                % makes a simple black/white image to see elevation shapes
                Elevshape=Elevations;
                Elevshape(Elevshape~=255)=1;
            end
             
            Yesterday=double(Yesterday);
            Today=double(Today);
            
    % Do data alignment check and output warning message if alignment is off.
            Todayshape=Today;
            Todayshape(Todayshape~=255)=1;
        
        if size(Elevations)~=size(Today)
            warning(' Misalligned day detected! skipping day.');
            Today=Yesterday;
        end   

%==========================================================================
%              Perform fractional snow cover calculations
%==========================================================================   

    %begin raster calculations
        for j = 1:size(Today,1)
            for k = 1:size(Today,2)
                
         % Performs a few logical operators to count up snow and cloud pixels     
                Zone=Elevations(j,k);
                if Zone<=15 && Zone~=0 
                     if Today(j,k)>=251
                         Today(j,k)=Yesterday(j,k);
                     else
                        Zonecount(i,Zone)=Zonecount(i,Zone)+1;
                     end

                % if yesterday had snow on a pixel, and today there are
                % clouds, this statement assumes that pixel is actually snow
                    if Today(j,k)==250 && Yesterday(j,k)<=100 && Yesterday(j,k)~=0
                        Today(j,k)=Yesterday(j,k);
                        amend(i)=amend(i)+1;
                        Clouds(i,Zone)=Clouds(i,Zone)+1;
                    end

                % updates snow and cloud pixel counts for the zone
                    if Today(j,k)<=100 && Today(j,k) >=1
                        Snow(i,Zone)=Snow(i,Zone)+Today(j,k)/100;
                    elseif Today(j,k)==250
                        Clouds(i,Zone)=Clouds(i,Zone)+1;
                    end

                end

            end
        end    

%==========================================================================
%                            Output progress
%==========================================================================

        Output(i,1)=str2num(DayNames{i});
        Output(i,2:16)=Snow(i,:)./Zonecount(i,:);    
        Output(i,17:31)=Clouds(i,:)./Zonecount(i,:);
        Output(i,32)=amend(i);
 
    % ensure no NaN values still exist
        Output(isnan(Output)) = 0;
    
    % correct any erroneous edge values to be no greater than 1
        for zz=size(Output,1)
            for yy=2:16
                if Output(zz,yy)>=1
                    Output(zz,yy)=1;
                end
            end
        end
    
    % output live progress to screen
        fprintf('Status: D=%3.0f, Y=%4.0f   %7.0f cloud corrections, %2.2f Basin Wide Snowcover \n'...
            ,Output(i,1),year,amend(i),100*sum(Snow(i,:))/sum(Zonecount(i,:)))     
    end
%==========================================================================
%            Correct the output for days with bad/null data
%========================================================================== 

    for a=1:(range(end)-1)
        if Output(a,1)~=a
            Output=[Output;zeros(1,size(Output,2))];
            Output((a+1):end,:)=Output(a:end-1,:);
            Output(a,1)=a;
        end
    end
    
    %fix day names in case they be incorrect.
    Output(1:range,1)=1:range;
    Output=Output(range,:);
    
    fprintf('Status: Output length= %3.0f days \n', length(Output));

%==========================================================================
%                            Write Output file
%==========================================================================

    Outpath=strcat(Root,'\Datos\Cuencas\',Basin,...
            '\Datos_Intermedia\DailySnowCover',YearStr,'.xls');
     
    % delete old output file if one already exists.    
    if exist(Outpath,'file')
        delete(Outpath);
    end
    
    xlswrite(Outpath,Output,'Sheet1');
    disp('Status: SCA output file has been successfully created!');
    fprintf('Time: SCA output processed in %2.2f minutes \n',(toc()/60));
    
    cd(strcat(Root,'\Ejecutables\Matlab'));

end











