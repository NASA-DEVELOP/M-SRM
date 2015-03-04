%==========================================================================
% Function to project Average Snow cover curves for forecasting purposes
%==========================================================================   
%
%
% Version 4/4/2014
%==========================================================================

function []=PredictSnow(root,Basin,year,FZS,FZW,plots)

%==========================================================================
% print status repor
    fprintf('Status: Basin = %s  \n Status: Year =  %4.0f \n',Basin,year)
    fprintf('Status: Forecasting temporal inputs for %4.0f days: \n \t\t (from day %4.0f to day %4.0f )\n',FZW,FZS,FZS+FZW);
    
    ProfilePath= strcat(root,'\Datos\Cuencas\',Basin,'\Parametros');
    MasterPath= strcat(root,'\Datos\Cuencas\',Basin,'\Datos_Intermedia');
    Ys=num2str(year); % the year in easy string format

% delete any existing output file
    OutName= strcat(MasterPath,'\ProjectedMaster',Ys,'.xls');
    if exist(OutName)
        delete(OutName)
    end

% Read in the profiles to forecast     
    SCAproff=xlsread(strcat(ProfilePath,'\SCA_Profile.xls'),'Sheet1','B1:P366');
    Tproff=xlsread(strcat(ProfilePath,'\Temperature_Profile.xls'),'Sheet1','B1:B366');
    PISproff=xlsread(strcat(ProfilePath,'\PrecipIS_Profile.xls'),'Sheet1','B1:B366');
    PNASAproff=xlsread(strcat(ProfilePath,'\PrecipNASA_Profile.xls'),'Sheet1','B1:B366');
    
% read in all the other parameters
    MeltF       =xlsread(strcat(ProfilePath,'\Melt_Factor.xls'));
    RCsnow      =xlsread(strcat(ProfilePath,'\RC_snow.xls'));
    RCPstations =xlsread(strcat(ProfilePath,'\RC_Pstations.xls'));
    RCPnasa     =xlsread(strcat(ProfilePath,'\RC_Pnasa.xls'));
    Tlapse      =xlsread(strcat(ProfilePath,'\Temperature_Lapse.xls'));
    Recess      =xlsread(strcat(ProfilePath,'\RecessionCoeff.xls'));
    
% Read in the actual data to which forecasts should be appended.    
    Actual=xlsread(strcat(MasterPath,'\Master',Ys,'.xls'),1,strcat('A2:AA',num2str(FZS)+1));
    SCAact=Actual(:,6:20);
    Tact=Actual(:,5);
    PISact=Actual(:,3);
    PNASAact=Actual(:,4);

%ensure theoretical profiles are of sufficient length
   while (FZS+FZW) > length(SCAproff)
        SCAproff=[SCAproff;SCAproff];
        Tproff=[Tproff;Tproff];
        PISproff=[PISproff;PISproff];
        PNASAproff=[PNASAproff;PNASAproff];
        
        MeltF=[MeltF;MeltF];
        RCsnow=[RCsnow;RCsnow];
        RCPstations=[RCPstations;RCPstations];
        RCPnasa=[RCPnasa;RCPnasa];
        Tlapse=[Tlapse;Tlapse];
        Recess=[Recess;Recess];
   end

% Fit the theoretical profile to the actual data by finding scaling factors
    a=7;
    for i=1:15
        SCAact(:,i)=smooth(SCAact(:,i),7);
        SCAscale(i)=mean(SCAact((FZS-a):FZS,i)./SCAproff((FZS-a):FZS,i));
        SCAscale(isnan(SCAscale)==1)=0; %sets NaN values to zero
        
        SCAproff(:,i)=SCAproff(:,i).*SCAscale(i);
    end
    
    Tscale     = mean(Tact((FZS-a):FZS)./Tproff((FZS-a):(FZS)));
    Tproff=Tproff*Tscale;
    
% create the arrays of projected values
    SCAprojected=[SCAact(1:FZS,:);SCAproff((FZS+1):(FZS+FZW),:)];
    Tprojected=[Tact(1:FZS);Tproff((FZS+1):(FZS+FZW))];
    PISprojected=[PISact(1:FZS);PISproff((FZS+1):(FZS+FZW))];    
    PNASAprojected=[PNASAact(1:FZS);PNASAproff((FZS+1):(FZS+FZW))];   

%==========================================================================
%                  Write ProjectedMaster file
%==========================================================================   

% Compile all the inputs for creation of a new projected master file
    Master=zeros(FZS+FZW,size(Actual,2));
    Master(1:length(Actual),:)=Actual;
    Master(:,3)=PISprojected;
    Master(:,4)=PNASAprojected;
    Master(:,5)=Tprojected;
    Master(:,6:20)=SCAprojected;
    
    Master(:,21)=MeltF(1:(FZS+FZW));
    Master(:,22)=RCsnow(1:(FZS+FZW));
    Master(:,23)=RCPstations(1:(FZS+FZW));
    Master(:,24)=RCPnasa(1:(FZS+FZW));
    Master(:,25)=Tlapse(1:(FZS+FZW));
    Master(:,26:27)=Recess(1:(FZS+FZW),:);

    Headers={'Day','Measured Discharge' ,'Station Precip','NASA Precip',...
        'Avg Temp' ,'Zone1', 'Zone2' ,'Zone3' ,'Zone4','Zone5',...
        'Zone6' ,'Zone7', 'Zone8' ,'Zone9','Zone10' ,'Zone11',...
        'Zone12', 'Zone13', 'Zone14', 'Zone15','DegDay' ,'RCsnow',...
        'RC_Pstations', 'RC_Pnasa','Tlapse', 'Recess_X','Recess_Y'};

    xlswrite(strcat(MasterPath,'\ProjectedMaster',Ys,'.xls'),Headers,'Sheet1','A1');
    xlswrite(strcat(MasterPath,'\ProjectedMaster',Ys,'.xls'),Master,'Sheet1','A2');
    
    disp('Status: Finished Forecasting Snow cover, Temperature, and Precipitation!');
    disp('NOTICE: If you wish to use custom forecasts for temperature and precipitation,');
    fprintf('        you may edit the master file stored in "ProjectedMaster%4.0f.xls]"!',year);
%==========================================================================
%              Plots, mostly just used to develop the code
%========================================================================== 

if plots =='y'
     SCAprojected(isnan(SCAprojected))=0;

     figure((year-2000)*10 +5);
     subplot(2,1,1);
        plot(SCAprojected(273:end,3:15));
        legend('1','2','3','4','5','6','7','8','9','10','11','12','13','14');
        title('Projected SCA Profiles');    
        axis([0 365-273 0 1]); grid on

     subplot(2,1,2);
        plot(Actual(273:end,3:11));
        legend('1','2','3','4','5','6','7','8','9','10','11','12','13','14');
        title('Actual SCA Profiles');    
        axis([0 365-273 0 1]); grid on

     figure((year-2000)*10 +2);
        subplot(2,1,1);
        plot(SCAprojected(:,3:11))
        legend('1','2','3','4','5','6','7','8','9','10','11','12','13','14');
        title('Full Projected SCA Profiles');    
        axis([0 365 0 1]); grid on

        subplot(2,1,2);
        plot(Actual(:,3:11));
        legend('1','2','3','4','5','6','7','8','9','10','11','12','13','14');
        title('Whole Actual SCA Profiles');    
        axis([0 365 0 1]); grid on
end
end



